const controlUrl = String(JELLYFIN_CONTROL_URL).trim();

if (controlUrl !== "" && controlUrl !== "undefined" && controlUrl !== "null") {
  const response = http.post(`${controlUrl}/__maestro/offline`, {
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({enabled: true}),
  });
  if (response.status !== 204) {
    throw new Error(`Could not put Jellyfin fixture offline: HTTP ${response.status}`);
  }
}
