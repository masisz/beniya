# Changelog

All notable changes to beniya will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2025-01-13

### Added
- **Floating Dialog System**: Modern floating confirmation dialogs for delete operations
- **Enhanced Delete Operations**: Comprehensive error handling with file system verification
- **English-Only Interface**: Complete localization to English, removing multi-language complexity
- **Character Width Calculation**: Proper Japanese character width handling for UI rendering
- **Debug Support**: `BENIYA_DEBUG=1` environment variable for detailed logging
- **Real-time Result Display**: Success/failure counts in floating dialogs
- **Post-deletion Verification**: File system checks to ensure actual deletion
- **HSL Color Model Support**: Intuitive color configuration with HSL values

### Changed
- **All UI messages converted to English** from Japanese
- **Delete confirmation workflow** now uses floating dialogs instead of command-line prompts
- **Error messages standardized** to English across all components
- **Documentation updated** to reflect English-only interface
- **Code style unified** with single quotes throughout

### Removed
- **Multi-language support** configuration and related code
- **Language setting environment variables** (`BENIYA_LANG`)
- **Language configuration files** support
- **Japanese UI messages** and localization infrastructure

### Technical
- **+290 lines** of new functionality in core keybind handler
- **New test files** for floating dialog system and delete operations
- **Enhanced error handling** patterns throughout codebase
- **Improved file system safety** checks and validation

For detailed information, see [CHANGELOG_v0.4.0.md](./CHANGELOG_v0.4.0.md)

## [0.3.0] - 2024-XX-XX

### Added
- Enhanced file operations and management features
- Improved user interface and navigation
- Additional configuration options

### Changed
- Performance improvements
- Bug fixes and stability enhancements

## [0.2.0] - 2024-XX-XX

### Added
- New features and functionality improvements
- Enhanced file management capabilities

### Changed
- User interface improvements
- Performance optimizations

## [0.1.0] - 2024-XX-XX

### Added
- Initial release of beniya
- Basic file manager functionality
- Vim-like key bindings
- File preview capabilities
- Multi-platform support

---

## Release Links

- [v0.4.0 Detailed Release Notes](./CHANGELOG_v0.4.0.md) - Comprehensive changelog with technical details
- [GitHub Releases](https://github.com/masisz/beniya/releases) - Download releases and view release history
- [Installation Guide](./README.md#installation) - How to install beniya
- [Usage Documentation](./README.md#usage) - Complete usage guide

## Version Numbering

beniya follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality additions  
- **PATCH** version for backwards-compatible bug fixes

## Contributing

When contributing to beniya:

1. Update the **[Unreleased]** section with your changes
2. Follow the existing changelog format
3. Link to detailed release notes for major versions
4. Include migration notes for breaking changes

For more information, see [Contributing Guidelines](./README.md#contributing).