# Turn a single Powershell script into a powerfull installer !

This is a proof of concept on a topic I especially like:

Helping people get the best fonts possible for modern uses.

# Ligatures & Fonts for the modern age

This installer allows one to install, in no particular order:

- [Iosevka TTC in 3 different variants](https://www.typography.com/fonts/operator/styles)
- [The legendary Fira Code (obviously)](https://github.com/tonsky/FiraCode)
- [Monoid (really good in lower rez)](https://larsenwork.com/monoid/)
- [Victor Mono the classy one](https://rubjo.github.io/victor-mono/)
- [JetBrains Mono, a Classic](https://www.jetbrains.com/lp/mono/)
- [Hasklig, a bit more Haskell-focused but great aswell](https://github.com/i-tu/Hasklig)
- [IBM Plex Mono, the company's great contribution](https://www.ibm.com/plex/)

# Compile from source

Jump into a Powershell window and just do

```powershell
Install-Module PS2EXE
```
At this point just run the pseudo-makefile

```powershell
.\make.ps1
```