import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex_library.dart';

void main() {
  group('PlexLibrary', () {
    group('isAudiobookLibrary', () {
      test('returns true for artist library with audnexus agent', () {
        final library = PlexLibrary(
          key: '1',
          title: 'Audiobooks',
          type: 'artist',
          agent: 'com.plexapp.agents.audnexus',
        );

        expect(library.isAudiobookLibrary, isTrue);
      });

      test('returns true for artist library with audiobooks agent', () {
        final library = PlexLibrary(
          key: '2',
          title: 'My Audiobooks',
          type: 'artist',
          agent: 'com.plexapp.agents.audiobooks',
        );

        expect(library.isAudiobookLibrary, isTrue);
      });

      test('returns true for artist library with audiobookshelf agent', () {
        final library = PlexLibrary(
          key: '3',
          title: 'Audiobook Library',
          type: 'artist',
          agent: 'com.plexapp.agents.audiobookshelf',
        );

        expect(library.isAudiobookLibrary, isTrue);
      });

      test('returns true for agent with uppercase letters (case-insensitive)', () {
        final library = PlexLibrary(
          key: '4',
          title: 'Audiobooks',
          type: 'artist',
          agent: 'com.plexapp.agents.AUDNEXUS',
        );

        expect(library.isAudiobookLibrary, isTrue);
      });

      test('returns true for agent with mixed case containing audiobook', () {
        final library = PlexLibrary(
          key: '5',
          title: 'Audiobooks',
          type: 'artist',
          agent: 'com.plexapp.agents.AudioBook.custom',
        );

        expect(library.isAudiobookLibrary, isTrue);
      });

      test('returns false for artist library with music agent (lastfm)', () {
        final library = PlexLibrary(
          key: '6',
          title: 'Music',
          type: 'artist',
          agent: 'com.plexapp.agents.lastfm',
        );

        expect(library.isAudiobookLibrary, isFalse);
      });

      test('returns false for artist library with music agent (plexmusic)', () {
        final library = PlexLibrary(
          key: '7',
          title: 'Music',
          type: 'artist',
          agent: 'com.plexapp.agents.plexmusic',
        );

        expect(library.isAudiobookLibrary, isFalse);
      });

      test('returns false for movie library', () {
        final library = PlexLibrary(
          key: '8',
          title: 'Movies',
          type: 'movie',
          agent: 'com.plexapp.agents.imdb',
        );

        expect(library.isAudiobookLibrary, isFalse);
      });

      test('returns false for show library', () {
        final library = PlexLibrary(
          key: '9',
          title: 'TV Shows',
          type: 'show',
          agent: 'com.plexapp.agents.thetvdb',
        );

        expect(library.isAudiobookLibrary, isFalse);
      });

      test('returns false for artist library with null agent', () {
        final library = PlexLibrary(
          key: '10',
          title: 'Music',
          type: 'artist',
          agent: null,
        );

        expect(library.isAudiobookLibrary, isFalse);
      });

      test('returns false for artist library with empty agent', () {
        final library = PlexLibrary(
          key: '11',
          title: 'Music',
          type: 'artist',
          agent: '',
        );

        expect(library.isAudiobookLibrary, isFalse);
      });

      test('returns false for photo library', () {
        final library = PlexLibrary(
          key: '12',
          title: 'Photos',
          type: 'photo',
          agent: 'com.plexapp.agents.none',
        );

        expect(library.isAudiobookLibrary, isFalse);
      });

      test('handles type with uppercase letters (case-insensitive)', () {
        final library = PlexLibrary(
          key: '13',
          title: 'Audiobooks',
          type: 'ARTIST',
          agent: 'com.plexapp.agents.audnexus',
        );

        expect(library.isAudiobookLibrary, isTrue);
      });

      test('handles type with mixed case (case-insensitive)', () {
        final library = PlexLibrary(
          key: '14',
          title: 'Audiobooks',
          type: 'Artist',
          agent: 'com.plexapp.agents.audnexus',
        );

        expect(library.isAudiobookLibrary, isTrue);
      });
    });

    group('libraryIcon', () {
      test('returns headphones icon for audiobook library', () {
        final library = PlexLibrary(
          key: '1',
          title: 'Audiobooks',
          type: 'artist',
          agent: 'com.plexapp.agents.audnexus',
        );

        expect(library.libraryIcon, equals(Icons.headphones));
      });

      test('returns movie icon for movie library', () {
        final library = PlexLibrary(
          key: '2',
          title: 'Movies',
          type: 'movie',
          agent: 'com.plexapp.agents.imdb',
        );

        expect(library.libraryIcon, equals(Icons.movie));
      });

      test('returns tv icon for show library', () {
        final library = PlexLibrary(
          key: '3',
          title: 'TV Shows',
          type: 'show',
          agent: 'com.plexapp.agents.thetvdb',
        );

        expect(library.libraryIcon, equals(Icons.tv));
      });

      test('returns music_note icon for music library', () {
        final library = PlexLibrary(
          key: '4',
          title: 'Music',
          type: 'artist',
          agent: 'com.plexapp.agents.lastfm',
        );

        expect(library.libraryIcon, equals(Icons.music_note));
      });

      test('returns photo icon for photo library', () {
        final library = PlexLibrary(
          key: '5',
          title: 'Photos',
          type: 'photo',
          agent: 'com.plexapp.agents.none',
        );

        expect(library.libraryIcon, equals(Icons.photo));
      });

      test('returns folder icon for unknown library type', () {
        final library = PlexLibrary(
          key: '6',
          title: 'Unknown',
          type: 'unknown',
          agent: 'com.plexapp.agents.unknown',
        );

        expect(library.libraryIcon, equals(Icons.folder));
      });

      test('handles type with uppercase letters for icon selection', () {
        final library = PlexLibrary(
          key: '7',
          title: 'Movies',
          type: 'MOVIE',
          agent: 'com.plexapp.agents.imdb',
        );

        expect(library.libraryIcon, equals(Icons.movie));
      });

      test('audiobook detection takes priority over artist icon', () {
        final audiobook = PlexLibrary(
          key: '8',
          title: 'Audiobooks',
          type: 'artist',
          agent: 'com.plexapp.agents.audnexus',
        );

        final music = PlexLibrary(
          key: '9',
          title: 'Music',
          type: 'artist',
          agent: 'com.plexapp.agents.lastfm',
        );

        expect(audiobook.libraryIcon, equals(Icons.headphones));
        expect(music.libraryIcon, equals(Icons.music_note));
      });
    });

    group('JSON serialization', () {
      test('deserializes from JSON correctly', () {
        final json = {
          'key': '1',
          'title': 'Audiobooks',
          'type': 'artist',
          'agent': 'com.plexapp.agents.audnexus',
          'scanner': 'Plex Music Scanner',
          'language': 'en',
          'uuid': '12345-67890',
          'updatedAt': 1699382400,
          'createdAt': 1699382400,
        };

        final library = PlexLibrary.fromJson(json);

        expect(library.key, equals('1'));
        expect(library.title, equals('Audiobooks'));
        expect(library.type, equals('artist'));
        expect(library.agent, equals('com.plexapp.agents.audnexus'));
        expect(library.scanner, equals('Plex Music Scanner'));
        expect(library.language, equals('en'));
        expect(library.uuid, equals('12345-67890'));
        expect(library.updatedAt, equals(1699382400));
        expect(library.createdAt, equals(1699382400));
        expect(library.isAudiobookLibrary, isTrue);
      });

      test('serializes to JSON correctly', () {
        final library = PlexLibrary(
          key: '1',
          title: 'Audiobooks',
          type: 'artist',
          agent: 'com.plexapp.agents.audnexus',
          scanner: 'Plex Music Scanner',
          language: 'en',
          uuid: '12345-67890',
          updatedAt: 1699382400,
          createdAt: 1699382400,
        );

        final json = library.toJson();

        expect(json['key'], equals('1'));
        expect(json['title'], equals('Audiobooks'));
        expect(json['type'], equals('artist'));
        expect(json['agent'], equals('com.plexapp.agents.audnexus'));
        expect(json['scanner'], equals('Plex Music Scanner'));
        expect(json['language'], equals('en'));
        expect(json['uuid'], equals('12345-67890'));
        expect(json['updatedAt'], equals(1699382400));
        expect(json['createdAt'], equals(1699382400));
      });

      test('handles null optional fields in JSON', () {
        final json = {
          'key': '1',
          'title': 'Movies',
          'type': 'movie',
        };

        final library = PlexLibrary.fromJson(json);

        expect(library.key, equals('1'));
        expect(library.title, equals('Movies'));
        expect(library.type, equals('movie'));
        expect(library.agent, isNull);
        expect(library.scanner, isNull);
        expect(library.language, isNull);
        expect(library.uuid, isNull);
        expect(library.updatedAt, isNull);
        expect(library.createdAt, isNull);
        expect(library.isAudiobookLibrary, isFalse);
      });
    });
  });
}
