# dotfiles

A collection of my personal dotfiles. These dotfiles are designed to work on macOS and Linux systems, providing a consistent and efficient environment. They include configurations for ZSH, Tmux, and various other tools that I use daily.

## Install

Clone this repository:

```shell
git clone https://github.com/dkadev/dotfiles.git ~/.dotfiles
```

Run the installation script to install pre-requisites and set up the dotfiles:

```shell
cd ~/.dotfiles
./install.sh
```

Script will ask for sudo permissions and install the following:

- [Make ZSH default shell](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH) if not already
- [Oh My ZSH](https://ohmyz.sh/)
- [powerlevel10k](https://github.com/romkatv/powerlevel10k) Theme for Oh My ZSH
- [bat](https://github.com/sharkdp/bat) cat on steroids
- [fzf](https://github.com/junegunn/fzf) command-line fuzzy finder
- [eza](https://github.com/eza-community/eza) A modern alternative to ls
- [ripgrep](https://github.com/BurntSushi/ripgrep) A line-oriented search tool that recursively searches your current directory for a regex pattern
- [tmux](https://github.com/tmux/tmux) Terminal multiplexer
- Nerd Font like [Hack](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/Hack/)

Then it will auto-symlink the dotfiles to your home directory.

## Plug and Play configuration only

If you don't want to run the installation script, you can still use the dotfiles by manually symlinking them to your home directory. This is useful if you already have ZSH, Oh My ZSH, and other dependencies installed.

### Using [GNU Stow](https://www.gnu.org/software/stow/) _(recommended)_

Install GNU Stow _(if not already installed)_

```markdown
Mac:      brew install stow
Ubuntu:   apt-get install stow
Fedora:   yum install stow
Arch:     pacman -S stow
```

Then simply use stow to install the dotfiles you want to use:

```shell
cd ~/.dotfiles
stow vim
stow tmux
```

### or Manual Installation

Create symbolic links for the configurations you want to use, e.g.:

```shell
ln -s ~/.dotfiles/vim/.vimrc ~/.vimrc
```

---

#### Additional configuration

Some of the configurations need additional setup or configuration. If that's the case you can find a `README.md` file in the application's directory. Make sure to take a look at it to see what else there is to do to make the configuration work on your system.
