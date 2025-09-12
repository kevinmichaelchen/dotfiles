#!/bin/sh
# Git aliases based on Oh-My-Zsh git plugin
# Shell-agnostic - can be sourced by bash, zsh, etc.

# Git command aliases
alias g='git'

# Add
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gau='git add --update'
alias gav='git add --verbose'
alias gap='git apply'
alias gapt='git apply --3way'

# Branch
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'
alias gbr='git branch --remote'
alias gbnm='git branch --no-merged'
alias gbm='git branch --merged'

# Bisect
alias gbs='git bisect'
alias gbsb='git bisect bad'
alias gbsg='git bisect good'
alias gbsr='git bisect reset'
alias gbss='git bisect start'

# Commit
alias gc='git commit --verbose'
alias gc!='git commit --verbose --amend'
alias gcn!='git commit --verbose --no-edit --amend'
alias gca='git commit --verbose --all'
alias gca!='git commit --verbose --all --amend'
alias gcan!='git commit --verbose --all --no-edit --amend'
alias gcans!='git commit --verbose --all --signoff --no-edit --amend'
alias gcam='git commit --all --message'
alias gcsm='git commit --signoff --message'
alias gcas='git commit --all --signoff'
alias gcasm='git commit --all --signoff --message'
alias gcb='git checkout -b'
alias gcf='git config --list'
alias gcmsg='git commit --message'
alias gcs='git commit --signoff'

# Clone
alias gcl='git clone --recurse-submodules'
alias gclean='git clean --interactive -d'

# Checkout
alias gco='git checkout'
alias gcor='git checkout --recurse-submodules'
alias gcom='git checkout $(git_main_branch)'
alias gcod='git checkout $(git_develop_branch)'

# Cherry-pick
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'

# Diff
alias gd='git diff'
alias gdca='git diff --cached'
alias gdcw='git diff --cached --word-diff'
alias gds='git diff --staged'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gdw='git diff --word-diff'

# Fetch
alias gf='git fetch'
alias gfa='git fetch --all --prune --jobs=10'
alias gfo='git fetch origin'

# GUI
alias gg='git gui citool'
alias gga='git gui citool --amend'

# Gitignore
alias gignore='git update-index --assume-unchanged'
alias gunignore='git update-index --no-assume-unchanged'

# Log
alias glg='git log --stat'
alias glgp='git log --stat --patch'
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glo='git log --oneline --decorate'
alias glol="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'"
alias glols="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --stat"
alias glod="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'"
alias glods="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' --date=short"
alias glola="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all"
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'

# Merge
alias gm='git merge'
alias gmom='git merge origin/$(git_main_branch)'
alias gmtl='git mergetool --no-prompt'
alias gmtlvim='git mergetool --no-prompt --tool=vimdiff'
alias gma='git merge --abort'

# Pull
alias gl='git pull'
alias glr='git pull --rebase'
alias glrv='git pull --rebase -v'
alias glra='git pull --rebase --autostash'
alias glrav='git pull --rebase --autostash -v'
alias glrom='git pull --rebase origin $(git_main_branch)'
alias glrum='git pull --rebase upstream $(git_main_branch)'

# Push
alias gp='git push'
alias gpd='git push --dry-run'
alias gpf='git push --force-with-lease --force-if-includes'
alias gpf!='git push --force'
alias gpoat='git push origin --all && git push origin --tags'
alias gpod='git push origin --delete'
alias gpr='git pull --rebase'
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias gpu='git push upstream'
alias gpv='git push --verbose'

# Rebase
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbd='git rebase $(git_develop_branch)'
alias grbi='git rebase --interactive'
alias grbm='git rebase $(git_main_branch)'
alias grbom='git rebase origin/$(git_main_branch)'
alias grbo='git rebase --onto'
alias grbs='git rebase --skip'

# Remote
alias gr='git remote'
alias gra='git remote add'
alias grmv='git remote rename'
alias grrm='git remote remove'
alias grset='git remote set-url'
alias grup='git remote update'
alias grv='git remote --verbose'

# Reset
alias grh='git reset'
alias grhh='git reset --hard'
alias groh='git reset origin/$(git_current_branch) --hard'
alias grm='git rm'
alias grmc='git rm --cached'

# Restore
alias grs='git restore'
alias grss='git restore --source'
alias grst='git restore --staged'

# Revert
alias grev='git revert'

# Show
alias gsh='git show'
alias gsps='git show --pretty=short --show-signature'

# Stash
alias gsta='git stash push'
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --text'
alias gstu='git stash --include-untracked'
alias gstall='git stash --all'

# Status
alias gss='git status --short'
alias gsb='git status --short --branch'
alias gst='git status'

# Submodule
alias gsu='git submodule update'
alias gsui='git submodule update --init'
alias gsuir='git submodule update --init --recursive'

# Switch
alias gsw='git switch'
alias gswc='git switch --create'
alias gswm='git switch $(git_main_branch)'
alias gswd='git switch $(git_develop_branch)'

# Tag
alias gts='git tag --sign'
alias gtv='git tag | sort -V'

# Worktree
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtls='git worktree list'
alias gwtmv='git worktree move'
alias gwtrm='git worktree remove'

# Helper functions that some aliases depend on
# These need to be defined for certain aliases to work
git_current_branch() {
  git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null
}

git_main_branch() {
  # Try to find main branch name (main or master)
  for branch in main master; do
    if git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return
    fi
  done
  echo main  # Default to main
}

git_develop_branch() {
  # Try to find develop branch name
  for branch in dev develop development; do
    if git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return
    fi
  done
  echo develop  # Default to develop
}