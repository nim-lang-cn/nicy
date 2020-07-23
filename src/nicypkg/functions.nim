import
  os,
  osproc,
  strformat,
  strutils,
  posix,
  terminal

type
  Color* = enum
    none = -1,
    black = 0,
    red = 1,
    green = 2,
    yellow = 3,
    blue = 4,
    magenta = 5,
    cyan = 6,
    white = 7,

when defined(bash): # shell switch during compilation using "-d:bash"
  proc isBash(): bool =
    result = true
elif defined(zsh): # or "-d:zsh"
  proc isBash(): bool =
    result = false
else: # or detect shell automatic
  proc isBash(): bool =
    result = false
    let ppid = getppid()
    let (o, err) = execCmdEx(fmt"ps -p {ppid} -oargs=")
    if err == 0:
      let name = o.strip()
      if name.endswith("bash"):
        result = true

let
  shellName* = # make sure the shell detection runs once only
    if isBash():
      "bash"
    else:
      "zsh" # default

proc zeroWidth*(s: string): string = 
  if shellName == "bash":
    return fmt"\[{s}\]"
  else:
    # zsh, default
    return fmt"%{{{s}%}}"

proc foreground*(s: string, color: Color): string =
  let c = "\x1b[" & $(ord(color)+30) & "m"
  result = fmt"{zeroWidth($c)}{s}"

proc background*(s: string, color: Color): string =
  let c = "\x1b[" & $(ord(color)+40) & "m"
  result = fmt"{zeroWidth($c)}{s}"

proc bold*(s: string): string = 
  const b = "\x1b[1m"
  result = fmt"{zeroWidth(b)}{s}"

proc underline*(s: string): string = 
  const u = "\x1b[4m"
  result = fmt"{zeroWidth(u)}{s}"

proc italics*(s: string): string = 
  const i = "\x1b[3m"
  result = fmt"{zeroWidth(i)}{s}"

proc reverse*(s: string): string = 
  const rev = "\x1b[7m"
  result = fmt"{zeroWidth(rev)}{s}"

proc reset*(s: string): string = 
  const res = "\x1b[0m"
  result = fmt"{s}{zeroWidth(res)}"

proc color*(s: string, fg, bg = Color.none, b, u, r = false): string =
  if s.len == 0:
    return
  result = s
  if fg != Color.none:
    result = foreground(result, fg)
  if bg != Color.none:
    result = background(result, bg)
  if b:
    result = bold(result)
  if u:
    result = underline(result)
  if r:
    result = reverse(result)
  result = reset(result)

proc horizontalRule*(c = '-'): string =
  for _ in 1 .. terminalWidth():
    result &= c
  result &= zeroWidth("\n")

proc tilde*(path: string): string =
  # donated by @misterbianco
  let home = getHomeDir()
  if path.startsWith(home):
    result = "~/" & path.split(home)[1]
  else:
    result = path

proc getCwd*(): string =
  result = try: 
    getCurrentDir() & " " 
  except OSError: 
    "[not found]"

proc virtualenv*(): string =
  let env = getEnv("VIRTUAL_ENV")
  result = extractFilename(env) & " "
  if env.len == 0:
    result = ""

proc gitBranch*(): string =
  let (o, err) = execCmdEx("git status")
  if err == 0:
    let firstLine = o.split("\n")[0].split(" ")
    result = firstLine[^1] & " "
  else:
    result = ""

proc gitStatus*(dirty, clean: string): string =
  let (o, err) = execCmdEx("git status --porcelain")
  result = if err == 0:
    if o.len != 0:
      dirty
    else:
      clean
  else:
    ""

proc user*(): string =
  result = $getpwuid(getuid()).pw_name

proc host*(): string =
  const size = 64 
  result = newString(size)
  discard gethostname(cstring(result), size)

proc uidsymbol*(root, user: string): string =
  result = if getuid() == 0: root else: user

proc returnCondition*(ok: string, ng: string, delimiter = "."): string = 
  result = fmt"%(?{delimiter}{ok}{delimiter}{ng})"

proc returnCondition*(ok: proc(): string, ng: proc(): string, delimiter = "."): string =
  result = returnCondition(ok(), ng(), delimiter)
