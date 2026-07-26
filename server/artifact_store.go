package main

import (
	"crypto/rand"
	"errors"
	"io/fs"
	"log"
	"math/big"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"time"
)

// --- Artifact store ---
//
// Uploaded logs and posters are the same on-disk artifact store: a flat
// directory of `<id><ext>` files whose mtime carries the creation time, written
// through a temp file, capped by a quota and swept for expiry. Files that
// cannot be deleted become pending debt so a failed removal never silently
// frees quota. artifactStore implements all of that once; the two flavours
// differ only in the policy fields below.

type artifactRemovalError struct {
	err error
}

func (e *artifactRemovalError) Error() string {
	return "artifact removal failed"
}

func (e *artifactRemovalError) Unwrap() error {
	return e.err
}

var errArtifactOutsideStore = errors.New("artifact path outside store")

func classifyRemovalError(err error) error {
	if err == nil || errors.Is(err, fs.ErrNotExist) {
		return nil
	}
	return err
}

func removeArtifact(removeFile func(string) error, root, path string) error {
	err := classifyRemovalError(removeFile(path))
	if err == nil {
		return nil
	}
	if !errors.Is(err, syscall.ENOTEMPTY) && !errors.Is(err, syscall.EEXIST) {
		return &artifactRemovalError{err: err}
	}
	if err := removeConfinedDirectory(root, path); err != nil {
		return &artifactRemovalError{err: err}
	}
	return nil
}

func removeConfinedDirectory(root, path string) error {
	info, err := os.Lstat(path)
	if err != nil {
		return classifyRemovalError(err)
	}
	if !info.IsDir() {
		return syscall.ENOTDIR
	}

	rootPath, err := filepath.Abs(root)
	if err != nil {
		return errArtifactOutsideStore
	}
	rootPath, err = filepath.EvalSymlinks(rootPath)
	if err != nil {
		return errArtifactOutsideStore
	}
	artifactPath, err := filepath.Abs(path)
	if err != nil {
		return errArtifactOutsideStore
	}
	artifactPath, err = filepath.EvalSymlinks(artifactPath)
	if err != nil {
		return errArtifactOutsideStore
	}
	relative, err := filepath.Rel(rootPath, artifactPath)
	if err != nil ||
		relative == "." ||
		relative == ".." ||
		filepath.IsAbs(relative) ||
		strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
		return errArtifactOutsideStore
	}
	return os.RemoveAll(artifactPath)
}

const idChars = "abcdefghijklmnopqrstuvwxyz0123456789"

func generateID(length int) string {
	b := make([]byte, length)
	for i := range b {
		n, _ := rand.Int(rand.Reader, big.NewInt(int64(len(idChars))))
		b[i] = idChars[n.Int64()]
	}
	return string(b)
}

func validID(id string, length int) bool {
	if len(id) != length {
		return false
	}
	for _, ch := range id {
		if !strings.ContainsRune(idChars, ch) {
			return false
		}
	}
	return true
}

// pendingRemoval is an artifact file that could not be deleted yet. Its size is
// unknown when the file could not be stat'ed or is not a regular file.
type pendingRemoval struct {
	size      int64
	sizeKnown bool
}

type artifactEntry struct {
	Filename    string
	Size        int64
	ContentType string
	CreatedAt   time.Time
	ExpiresAt   time.Time
}

type artifactStore struct {
	entries         map[string]artifactEntry
	pendingRemovals map[string]pendingRemoval
	dir             string
	name            string // log prefix, e.g. "logs"
	maxAge          time.Duration
	removeFile      func(string) error

	// Policy. generateID is a field so tests can force ID collisions.
	generateID     func() string
	idFromFilename func(filename string) (string, bool)
	// acceptLoaded reports whether a file found on disk is a usable artifact
	// and returns the content type recorded for it.
	acceptLoaded func(filename string, size int64) (string, bool)
	// limit caps accountedLocked, measured in the units cost returns:
	// one per artifact for logs, bytes for posters.
	limit       int64
	cost        func(size int64) int64
	pendingCost func(pending pendingRemoval) int64
	// evictToFit admits a new artifact by evicting the oldest live ones;
	// stores that leave it false reject the upload with errFull instead.
	evictToFit bool
	// retryKnownDebtOnPut retries only debt whose size is accounted, leaving
	// unknown debt to periodic cleanup.
	retryKnownDebtOnPut bool
	errFull             error

	used           int64 // accounted cost of live entries
	pendingDebt    int64 // accounted cost of pending removals
	unknownPending int   // pending removals kept out of the quota
	startupErr     error
	mu             sync.RWMutex
}

func (as *artifactStore) filePath(filename string) string {
	return filepath.Join(as.dir, filename)
}

func (as *artifactStore) accountedLocked() int64 {
	return as.used + as.pendingDebt
}

func (as *artifactStore) loadExisting(now time.Time) error {
	as.mu.Lock()
	defer as.mu.Unlock()

	files, err := os.ReadDir(as.dir)
	if err != nil {
		log.Printf("%s: failed to read dir %s: %v", as.name, as.dir, err)
		return nil
	}
	var removalErr error
	drop := func(file fs.DirEntry) {
		size, sizeKnown := dirEntrySize(file)
		removalErr = errors.Join(removalErr, as.removeUntrackedLocked(file.Name(), size, sizeKnown))
	}
	for _, file := range files {
		filename := file.Name()
		if file.IsDir() || strings.HasSuffix(filename, ".tmp") {
			drop(file)
			continue
		}
		id, ok := as.idFromFilename(filename)
		if !ok {
			drop(file)
			continue
		}
		info, infoErr := file.Info()
		if infoErr != nil || !info.Mode().IsRegular() {
			drop(file)
			continue
		}
		contentType, ok := as.acceptLoaded(filename, info.Size())
		if !ok {
			drop(file)
			continue
		}
		// Several extensions can map to one id; keep the first and drop the rest.
		if _, duplicate := as.entries[id]; duplicate {
			drop(file)
			continue
		}
		createdAt := info.ModTime()
		as.entries[id] = artifactEntry{
			Filename:    filename,
			Size:        info.Size(),
			ContentType: contentType,
			CreatedAt:   createdAt,
			ExpiresAt:   createdAt.Add(as.maxAge),
		}
		as.used += as.cost(info.Size())
	}
	removalErr = errors.Join(removalErr, as.cleanupExpiredLocked(now))
	removalErr = errors.Join(removalErr, as.evictOldestLocked(0))
	return removalErr
}

// put writes data as `<id><ext>` once the quota allows it.
func (as *artifactStore) put(data []byte, ext, contentType string, now time.Time) (string, artifactEntry, error) {
	as.mu.Lock()
	defer as.mu.Unlock()

	size := int64(len(data))
	cost := as.cost(size)
	// Reclaim what the quota can get back without touching live entries.
	// Removal failures stay accounted as debt instead of blocking the write.
	_ = as.retryPendingLocked(as.retryKnownDebtOnPut)
	_ = as.cleanupExpiredLocked(now)
	var headroom int64
	if as.evictToFit {
		headroom = cost
	}
	if err := as.evictOldestLocked(headroom); err != nil {
		return "", artifactEntry{}, err
	}
	if as.accountedLocked()+cost > as.limit {
		return "", artifactEntry{}, as.errFull
	}

	id := as.generateID()
	for {
		if _, exists := as.entries[id]; !exists {
			if _, err := os.Stat(as.filePath(id + ext)); errors.Is(err, fs.ErrNotExist) {
				break
			}
		}
		id = as.generateID()
	}

	filename := id + ext
	path := as.filePath(filename)
	tmpPath := path + ".tmp"
	if err := os.WriteFile(tmpPath, data, 0644); err != nil {
		as.cleanupFailedTempLocked(tmpPath)
		return "", artifactEntry{}, err
	}
	if err := os.Rename(tmpPath, path); err != nil {
		as.cleanupFailedTempLocked(tmpPath)
		return "", artifactEntry{}, err
	}
	_ = os.Chtimes(path, now, now)

	entry := artifactEntry{
		Filename:    filename,
		Size:        size,
		ContentType: contentType,
		CreatedAt:   now,
		ExpiresAt:   now.Add(as.maxAge),
	}
	as.entries[id] = entry
	as.used += cost
	return id, entry, nil
}

// lookupEntry returns the live entry for id, dropping it when it has expired.
// match, when set, rejects entries the caller did not ask for before expiry is
// considered, so a mismatched request never triggers a removal.
func (as *artifactStore) lookupEntry(
	id string,
	now time.Time,
	match func(artifactEntry) bool,
) (artifactEntry, bool, error) {
	as.mu.Lock()
	defer as.mu.Unlock()
	entry, ok := as.entries[id]
	if !ok || (match != nil && !match(entry)) {
		return artifactEntry{}, false, nil
	}
	if !now.Before(entry.ExpiresAt) {
		if err := as.deleteEntryLocked(id); err != nil {
			return artifactEntry{}, false, err
		}
		return artifactEntry{}, false, nil
	}
	return entry, true, nil
}

func (as *artifactStore) cleanup(now time.Time) error {
	as.mu.Lock()
	defer as.mu.Unlock()
	return as.cleanupLocked(now)
}

func (as *artifactStore) cleanupLocked(now time.Time) error {
	removalErr := as.retryPendingLocked(false)
	removalErr = errors.Join(removalErr, as.cleanupExpiredLocked(now))
	return errors.Join(removalErr, as.evictOldestLocked(0))
}

func (as *artifactStore) cleanupExpiredLocked(now time.Time) error {
	var removalErr error
	for id, entry := range as.entries {
		if !now.Before(entry.ExpiresAt) {
			removalErr = errors.Join(removalErr, as.deleteEntryLocked(id))
		}
	}
	return removalErr
}

// evictOldestLocked deletes oldest-first until headroom more cost units fit.
func (as *artifactStore) evictOldestLocked(headroom int64) error {
	for as.accountedLocked()+headroom > as.limit && len(as.entries) > 0 {
		var oldestID string
		var oldest artifactEntry
		for id, entry := range as.entries {
			if oldestID == "" || entry.CreatedAt.Before(oldest.CreatedAt) {
				oldestID = id
				oldest = entry
			}
		}
		if err := as.deleteEntryLocked(oldestID); err != nil {
			return err
		}
	}
	return nil
}

func (as *artifactStore) deleteEntryLocked(id string) error {
	entry, ok := as.entries[id]
	if !ok {
		return nil
	}
	if err := removeArtifact(as.removeFile, as.dir, as.filePath(entry.Filename)); err != nil {
		return err
	}
	delete(as.entries, id)
	as.used -= as.cost(entry.Size)
	return nil
}

// removeUntrackedLocked deletes a file the index does not own, recording it as
// pending debt when the removal fails.
func (as *artifactStore) removeUntrackedLocked(filename string, size int64, sizeKnown bool) error {
	if err := removeArtifact(as.removeFile, as.dir, as.filePath(filename)); err != nil {
		as.addPendingLocked(filename, size, sizeKnown)
		return err
	}
	as.dropPendingLocked(filename)
	return nil
}

func (as *artifactStore) retryPendingLocked(knownDebtOnly bool) error {
	var removalErr error
	for filename, pending := range as.pendingRemovals {
		if knownDebtOnly && !pending.sizeKnown {
			continue
		}
		if err := removeArtifact(as.removeFile, as.dir, as.filePath(filename)); err != nil {
			removalErr = errors.Join(removalErr, err)
			continue
		}
		as.dropPendingLocked(filename)
	}
	return removalErr
}

func (as *artifactStore) cleanupFailedTempLocked(tmpPath string) {
	size, sizeKnown := fileSize(tmpPath)
	_ = as.removeUntrackedLocked(filepath.Base(tmpPath), size, sizeKnown)
}

func (as *artifactStore) addPendingLocked(filename string, size int64, sizeKnown bool) {
	if _, exists := as.pendingRemovals[filename]; exists {
		return
	}
	pending := pendingRemoval{size: size, sizeKnown: sizeKnown}
	as.pendingRemovals[filename] = pending
	as.pendingDebt += as.pendingCost(pending)
	if !sizeKnown {
		as.unknownPending++
	}
}

func (as *artifactStore) dropPendingLocked(filename string) {
	pending, exists := as.pendingRemovals[filename]
	if !exists {
		return
	}
	delete(as.pendingRemovals, filename)
	as.pendingDebt -= as.pendingCost(pending)
	if !pending.sizeKnown {
		as.unknownPending--
	}
}

func dirEntrySize(file fs.DirEntry) (int64, bool) {
	info, err := file.Info()
	if err != nil || !info.Mode().IsRegular() {
		return 0, false
	}
	return info.Size(), true
}

func fileSize(path string) (int64, bool) {
	info, err := os.Stat(path)
	if err != nil || !info.Mode().IsRegular() {
		return 0, false
	}
	return info.Size(), true
}
