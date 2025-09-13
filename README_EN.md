# beniya

A terminal-based file manager written in Ruby

[日本語版](./README.md) | **English**

## Overview

beniya is a terminal-based file manager inspired by Yazi. It's implemented in Ruby with plugin support, providing lightweight and fast operations for file browsing, management, and searching.

## Features

- **Lightweight & Simple**: A lightweight file manager written in Ruby
- **Intuitive Operation**: Vim-like key bindings
- **File Preview**: View text file contents on the fly
- **File Selection & Operations**: Select multiple files, move, copy, and delete
- **Base Directory Operations**: Batch file operations to startup directory
- **Real-time Filter**: Filter files by name using s key
- **Advanced Search**: Powerful search using fzf and rga
- **Multi-platform**: Runs on macOS, Linux, and Windows
- **External Editor Integration**: Open files with your favorite editor
- **English Interface**: Clean English interface
- **Health Check**: System dependency verification

## Installation

```bash
gem install beniya
```

Or add it to your Gemfile:

```ruby
gem 'beniya'
```

## Usage

### Basic Launch

```bash
beniya           # Launch in current directory
beniya /path/to  # Launch in specified directory
```

### Health Check

```bash
beniya -c                # Check system dependencies
beniya --check-health    # Same as above
beniya --help           # Show help message
```

### Key Bindings

#### Basic Navigation

| Key           | Function                      |
| ------------- | ----------------------------- |
| `j`           | Move down                     |
| `k`           | Move up                       |
| `h`           | Move to parent directory      |
| `l` / `Enter` | Enter directory / Select file |

#### Quick Navigation

| Key | Function               |
| --- | ---------------------- |
| `g` | Move to top of list    |
| `G` | Move to bottom of list |

#### File Operations

| Key | Function                                |
| --- | --------------------------------------- |
| `o` | Open selected file with external editor |
| `e` | Open current directory in file explorer |
| `r` | Refresh directory contents              |
| `a` | Create new file                         |
| `A` | Create new directory                    |

#### File Selection & Operations

| Key     | Function                                    |
| ------- | ------------------------------------------- |
| `Space` | Select/deselect files and directories      |
| `m`     | Move selected items to base directory      |
| `p`     | Copy selected items to base directory      |
| `x`     | Delete selected items                       |

#### Real-time Filter

| Key         | Function                               |
| ----------- | -------------------------------------- |
| `s`         | Start filter mode / Re-edit filter     |
| Text input  | Filter files by name (in filter mode)  |
| `Enter`     | Keep filter and return to normal mode  |
| `ESC`       | Clear filter and return to normal mode |
| `Backspace` | Delete character (in filter mode)      |

#### Search Functions

| Key | Function                                 |
| --- | ---------------------------------------- |
| `f` | File name search with fzf (with preview) |
| `F` | File content search with rga             |

#### System Operations

| Key | Function    |
| --- | ----------- |
| `q` | Quit beniya |

### File Selection & Operations

#### File and Directory Selection (`Space`)

- **Select/Deselect**: Use `Space` key to select or deselect files and directories
- **Multiple Selection**: Select multiple files and directories simultaneously
- **Visual Display**: Selected items are marked with ✓ and highlighted in green
- **Selection Counter**: The number of selected items is shown on the second line of the screen

#### Base Directory Operations

The directory where beniya starts becomes the **base directory**, which serves as the destination for move and copy operations.

| Operation | Key | Function                                |
| --------- | --- | --------------------------------------- |
| **Move**  | `m` | Move selected items to base directory  |
| **Copy**  | `p` | Copy selected items to base directory  |
| **Delete** | `x` | Delete selected items                   |

#### Delete Operation Details

- **Floating Dialog Confirmation**: Modern floating window with clear options
- **Visual Feedback**: Red border and warning colors for attention
- **Safe Operation**: Double confirmation before deletion
- **Comprehensive Error Handling**: Detailed error messages for failed deletions
- **Real-time Result Display**: Shows success/failure count in floating dialog
- **File System Verification**: Confirms actual deletion before reporting success
- **Debug Support**: Optional debug logging with BENIYA_DEBUG=1

#### Operation Workflow

```
1. Space → Select files/directories (multiple selection possible)
2. Choose operation key:
   - m → Move to base directory
   - p → Copy to base directory
   - x → Delete
3. Floating Dialog → Confirm with Y/N, ESC to cancel
4. Result Display → Review operation results in floating window
```

#### Safety Features

- **Floating Confirmation Dialog**: Modern floating window interface for confirmations
- **Visual Warning System**: Red borders and colors for dangerous operations
- **Duplicate Check**: Automatically skip files with same names
- **Error Handling**: Proper handling of permission errors and other issues
- **Operation Log**: Detailed display of operation results in floating dialogs
- **Post-deletion Verification**: Confirms files are actually deleted from filesystem

### Filter Feature

#### Real-time Filter (`s`)

- **Start Filter**: Press `s` to enter filter mode
- **Text Input Filtering**: Supports Japanese, English, numbers, and symbols
- **Real-time Updates**: Display updates with each character typed
- **Keep Filter**: Press `Enter` to maintain filter while returning to normal operations
- **Clear Filter**: Press `ESC` to clear filter and return to normal display
- **Re-edit**: Press `s` again while filter is active to re-edit
- **Character Deletion**: Use `Backspace` to delete characters, auto-clear when empty

#### Usage Example

```
1. s → Start filter mode
2. ".rb" → Show only Ruby files
3. Enter → Keep filter, return to normal operations
4. j/k → Navigate within filtered results
5. s → Re-edit filter
6. ESC → Clear filter
```

### Search Features

#### File Name Search (`f`)

- Interactive file name search using `fzf`
- Real-time preview display
- Selected files automatically open in external editor

#### File Content Search (`F`)

- Advanced file content search using `rga` (ripgrep-all)
- Searches PDFs, Word documents, text in images, and more
- Filter results with fzf and jump to specific lines

### Required External Tools

The following tools are required for search functionality:

```bash
# macOS (Homebrew)
brew install fzf rga

# Ubuntu/Debian
apt install fzf
# rga requires separate installation: https://github.com/phiresky/ripgrep-all

# Other Linux distributions
# Installation via package manager or manual installation required
```

## Configuration

### Color Configuration (Customization)

beniya allows you to customize colors for file types and UI elements. It supports intuitive color specification using the HSL color model.

#### Supported Color Formats

```ruby
# HSL (Hue, Saturation, Lightness) - Recommended format
{hsl: [220, 80, 60]}  # Hue 220°, Saturation 80%, Lightness 60%

# RGB (Red, Green, Blue)
{rgb: [100, 150, 200]}

# HEX (Hexadecimal)
{hex: "#6496c8"}

# Traditional symbols
:blue, :red, :green, :yellow, :cyan, :magenta, :white, :black

# ANSI color codes
"34" or 34
```

#### Configuration Example

```ruby
# ~/.config/beniya/config.rb
COLORS = {
  # HSL color specification (intuitive and easy to adjust)
  directory: {hsl: [220, 80, 60]},    # Blue-ish for directories
  file: {hsl: [0, 0, 90]},            # Light gray for regular files
  executable: {hsl: [120, 70, 50]},   # Green-ish for executable files
  selected: {hsl: [50, 90, 70]},      # Yellow for selected items
  preview: {hsl: [180, 60, 65]},      # Cyan for preview panel

  # You can also mix different formats
  # directory: :blue,                 # Symbol
  # file: {rgb: [200, 200, 200]},     # RGB
  # executable: {hex: "#00aa00"},     # HEX
}
```

#### About HSL Color Model

- **Hue**: 0-360 degrees (0=red, 120=green, 240=blue)
- **Saturation**: 0-100% (0=gray, 100=vivid)
- **Lightness**: 0-100% (0=black, 50=normal, 100=white)

#### Configurable Items

- `directory`: Directory color
- `file`: Regular file color
- `executable`: Executable file color
- `selected`: Selected item color
- `preview`: Preview panel color

## Development

### Requirements

- Ruby 2.7.0 or later
- Required gems: io-console, pastel, tty-cursor, tty-screen

### Running Development Version

```bash
git clone https://github.com/masisz/beniya
cd beniya
bundle install
./exe/beniya
```

### Running Tests

```bash
bundle exec rake test
```

## Supported Platforms

- **macOS**: Native support
- **Linux**: Native support
- **Windows**: Basic functionality supported

## Contributing

Bug reports and feature requests are welcome at [GitHub Issues](https://github.com/masisz/beniya/issues).

Pull requests are also welcome!

### Development Guidelines

1. Follow existing code style and conventions
2. Add tests for new features
3. Update documentation as needed
4. Test on multiple platforms when possible

## License

MIT License

