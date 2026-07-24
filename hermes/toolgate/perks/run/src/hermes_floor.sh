# hermes_floor.sh — the destructive floor as a PURE PREDICATE. This file EXECUTES NOTHING:
# it defines a regex table and floor_verdict(), and is sourced by
#   hermes_exec.sh        — enforcement (the only file in this perk that runs a command)
#   hermes_floor_check.sh — self-test (classifies the pinned case table, executes none of it)
# Keeping the predicate execution-free is what makes it testable: a floor test can never
# reach an execution path, because this file does not contain one.
#
# Defense-in-depth — confinement is the primary guarantee. Kept deliberately SMALL and
# literal: every added rule is bash that can be gotten wrong, and the sandbox already
# neutralizes the host. We protect the ONE real thing in the box (the bound workspace)
# and refuse the classic irrecoverables.
#
# Matching is on a NORMALIZED copy of the command string (tabs/newlines to spaces, quote
# characters stripped, whitespace runs collapsed). This is not a shell parser; it is a
# conservative denylist that fails toward blocking — `echo "rm -rf /"` is blocked, a false
# positive we accept. Confinement, not this table, stops a determined bypass.

# a bare rm of root / home / cwd / glob as the whole target
RE_RM_ROOT='(^|[^[:alnum:]_])rm([[:space:]]+-[^[:space:]]+)*[[:space:]]+(/|~|[.]|[*])([[:space:]]|$)'
# a RECURSIVE rm whose target is an absolute path, home, or a workspace root var.
# The target may follow IMMEDIATELY after the flag's separating space: the pre-fix version
# demanded a second separator, which let `rm -rf $HOME` and `rm -fr /etc` through.
# `[^;|&]*` keeps flag and target inside ONE command segment (never across && ; |).
RE_RM_RECURSE_ABS='(^|[^[:alnum:]_])rm[[:space:]]([^;|&]*[[:space:]])?-[^[:space:]]*[rR]([^;|&]*[[:space:]])?(/|~|[$][{]?(HOME|RECORD_STORE|WORKDIR)([^[:alnum:]_]|$))'
RE_MKFS='(^|[^[:alnum:]_])(mkfs|mke2fs|fsck)[.a-z0-9]*[[:space:]]'
RE_DD_DEV='(^|[^[:alnum:]_])dd[[:space:]].*of=/dev/'
RE_REDIR_DEV='>[[:space:]]*/dev/(sd|nvme|mmcblk|vd|hd)'
RE_FORKBOMB=':[[:space:]]*\([[:space:]]*\)[[:space:]]*\{'
RE_WRITE_SYSDIR='>[[:space:]]*/(etc|usr|bin|lib|sbin|boot|sys|proc)([/[:space:]]|$)'

floor_verdict() {   # $1 = raw command string → prints "allow" | "block:<reason>"; returns 0 / 1
  local n="$1" q="'" dq='"'
  n="${n//$'\t'/ }"
  n="${n//$'\n'/ }"
  n="${n//$q/}"
  n="${n//$dq/}"
  while [[ "$n" == *"  "* ]]; do n="${n//  / }"; done

  local reason=""
  if   [[ "$n" =~ $RE_RM_ROOT ]];        then reason="delete of root/home/cwd/glob"
  elif [[ "$n" =~ $RE_RM_RECURSE_ABS ]]; then reason="recursive delete of an absolute/home/workspace path"
  elif [[ "$n" =~ $RE_MKFS ]];           then reason="mkfs/fsck"
  elif [[ "$n" =~ $RE_DD_DEV ]];         then reason="dd to a device"
  elif [[ "$n" =~ $RE_REDIR_DEV ]];      then reason="redirect to raw device"
  elif [[ "$n" =~ $RE_FORKBOMB ]];       then reason="fork bomb"
  elif [[ "$n" =~ $RE_WRITE_SYSDIR ]];   then reason="write to a system directory"
  fi

  if [[ -n "$reason" ]]; then printf 'block:%s\n' "$reason"; return 1; fi
  printf 'allow\n'
  return 0
}
