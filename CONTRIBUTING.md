# Contributing

## Getting Started

1. Fork and clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `dart run build_runner build` to generate code
4. Start developing!

## Development

- Follow Dart/Flutter conventions
- Run `flutter analyze` before submitting
- Test your changes thoroughly

## Internationalization (i18n)

This project uses `slang` for internationalization with JSON files.

### Adding New Strings

1. Add your string to `lib/i18n/strings.i18n.json`:
   ```json
   {
     "section": {
       "myNewString": "My new text"
     }
   }
   ```

2. Run `dart run slang` to regenerate translation files

3. Use in your code:
   ```dart
   Text(t.section.myNewString)
   ```

### Adding New Languages

1. Create new JSON file: `lib/i18n/strings_[locale].i18n.json`
2. Copy structure from `strings.i18n.json` and translate values
3. Run `dart run slang` to regenerate files

### Guidelines

- Organize strings logically in nested objects
- Use camelCase for keys
- Keep strings concise and clear
- Always run `dart run slang` after changes
