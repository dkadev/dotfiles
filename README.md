# dotfiles

A collection of my personal dotfiles. 

Here's a little preview of what it looks like with [base16-shell](https://github.com/chriskempson/base16-shell)'s _Pico_ theme enabled.

Tool used to preview themes is [base16-shell-preview](https://github.com/nvllsvm/base16-shell-preview).

![terminator screenshot](screenshot.png)

## Install

TODO: add installation script

- Good friend [Ulauncher](https://ulauncher.io/#Download)
- Install any Nerd Font like [Hack NF](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/Hack/Regular/complete/) for terminal icons (you would probably need [Font manager](https://github.com/FontManager/font-manager))
- [Make ZSH default shell](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH) if not already
- Oh My ZSH -> https://ohmyz.sh/
- [powerlevel10k](https://github.com/romkatv/powerlevel10k) Theme for Oh My ZSH
- [bat](https://github.com/sharkdp/bat) cat on steroids
- [lsd](https://github.com/Peltoche/lsd) ls on steroids

## Configuration
First step is to clone this repository:
```jsx
git clone https://github.com/dkadev/dotfiles.git ~/.dotfiles
```

### Using [GNU Stow](https://www.gnu.org/software/stow/) _(recommended)_
Install GNU Stow _(if not already installed)_
```jsx
Mac:      brew install stow
Ubuntu:   apt-get install stow
Fedora:   yum install stow
Arch:     pacman -S stow
```
Then simply use stow to install the dotfiles you want to use:
```
cd ~/.dotfiles
stow vim
stow tmux
```
### or Manual Installation
Create symbolic links for the configurations you want to use, e.g.:
```
ln -s ~/.dotfiles/vim/.vimrc ~/.vimrc
```

## Appearance

[Qogir-theme](https://github.com/vinceliuice/Qogir-theme)


---
Use base16 colors
------------------------
To get the most out of my dotfiles I recommend installing [base16-shell](https://github.com/chriskempson/base16-shell) on your system. This will allow you to have unified colors in all your command line applications. If you see that some colors are off when using my setup, installing base16-shell is most likely the way to fix it.

Additional configuration
------------------------
Some of the configurations need additional setup or configuration. If that's the case you can find a `README.md` file in the application's directory. Make sure to take a look at it to see what else there is to do to make the configuration work on your system.
