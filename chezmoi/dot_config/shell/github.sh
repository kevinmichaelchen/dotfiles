#!/bin/sh
# GitHub CLI (gh) aliases
# Shell-agnostic - can be sourced by bash, zsh, etc.

# === Pull Requests (primary workflow) ===
alias ghpr='gh pr'                  # PR base command
alias ghprc='gh pr create'          # Create PR
alias ghprcw='gh pr create --web'   # Create PR in browser
alias ghprl='gh pr list'            # List PRs
alias ghprv='gh pr view'            # View PR
alias ghprvw='gh pr view --web'     # View PR in browser
alias ghprco='gh pr checkout'       # Checkout PR branch
alias ghprs='gh pr status'          # PR status (current, created, review requested)
alias ghprm='gh pr merge'           # Merge PR
alias ghprd='gh pr diff'            # View PR diff
alias ghprr='gh pr ready'           # Mark PR as ready for review
alias ghprre='gh pr review'         # Submit PR review
alias ghprcl='gh pr close'          # Close PR

# === Issues ===
alias ghi='gh issue'                # Issue base command
alias ghic='gh issue create'        # Create issue
alias ghicw='gh issue create --web' # Create issue in browser
alias ghil='gh issue list'          # List issues
alias ghiv='gh issue view'          # View issue
alias ghivw='gh issue view --web'   # View issue in browser
alias ghis='gh issue status'        # Issue status (assigned, mentioned, opened)
alias ghie='gh issue edit'          # Edit issue
alias ghicl='gh issue close'        # Close issue
alias ghiro='gh issue reopen'       # Reopen issue
alias ghicm='gh issue comment'      # Comment on issue

# === Repository (commonly used) ===
alias ghrv='gh repo view'           # View repo info
alias ghrvw='gh repo view --web'    # Open repo in browser
alias ghrc='gh repo clone'          # Clone repo
alias ghrf='gh repo fork'           # Fork repo

# === Browse (quick access) ===
alias ghb='gh browse'               # Open current repo in browser
alias ghbp='gh browse --projects'   # Open projects tab
alias ghbs='gh browse --settings'   # Open settings tab

# === Search ===
alias ghsp='gh search prs'          # Search PRs
alias ghsi='gh search issues'       # Search issues
