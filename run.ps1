param(
    [string]$ApiBaseUrl = "http://10.0.2.2:3000",
    [string]$GitHubClientId = "Ov23liOusOtj7YwFgtiZ"
)

flutter run `
    --dart-define=API_BASE_URL=$ApiBaseUrl `
    --dart-define=GITHUB_CLIENT_ID=$GitHubClientId
