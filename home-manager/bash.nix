{ pkgs, stable-packages, localBin, sources, homeManager, configureExtraBashConfig }: with pkgs;
let
  v = "nvim";
  d = "${docker}/bin/docker";
  g = "${git}/bin/git";
  copy = "${xclip}/bin/xclip -se c";

  noColor = "\\e[0m\\]";
  yellow = "\\e[0;33m\\]";
  purple = "\\e[0;35m\\]";
  teal = "\\e[0;36m\\]";
  orange = "\\e[38;5;214m\\]";
  spacer = "\\n\\e[99;1H\\]";
  userAtHost = orange + "\\u@\\h " + noColor;
  directory = yellow + "\\w" + noColor;
  gitStatus = teal + "\\$(__git_ps1) " + noColor;
  time = purple + "\\A " + noColor;
  newline = "\\n";
  prompt = "\\$(show_status_code) ";
  envName = "$ENV_NAME";
  ps1 = spacer + userAtHost + directory + gitStatus + time + newline + envName + prompt;
in
{
  enable = true;
  historySize = 1000000;
  historyFileSize = 1000000;
  historyControl = [ "ignoredups" "ignorespace" "erasedups" ];
  historyIgnore = [ ];
  shellOptions = [
    "histappend"
    "checkwinsize"
    "extglob"
    "globstar"
    "dotglob"
    "checkjobs"
    "expand_aliases"
    "direxpand"
  ];

  sessionVariables = { };

  shellAliases = {
    inherit v d g copy;
    cdn = "cd ~/nixos";
    cdr = "cd $SOURCES";
    rm = "rm -I";
    ls = "ls --color";
    la = "ls -A";
    lr = "ls -R";
    ll = "ls -alh";
    dps = "${d} ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'";
    dpr = "${d} system prune --all --volumes";
    gs = "${g} s";
    untar = "tar -xvf";
    past = "${copy} -o";
    nsw = "sudo ${cpulimit}/bin/cpulimit -i -l 650 -- nixos-rebuild switch";
  };

  bashrcExtra = ''
    LOCAL_BIN="${localBin}"
    SOURCES="${sources}"
    PS1="${ps1}"

    export PATH="${localBin}:${homeManager}/files/bin:$PATH"
    export TERMINAL="${xfce.xfce4-terminal}"
    export LESS="-iFR -z-4 -j5"
    export ACK_PAGER="${less} -FRX"

    # Colorful man pages
    export LESS_TERMCAP_mb=$'\e[1;32m'
    export LESS_TERMCAP_md=$'\e[1;32m'
    export LESS_TERMCAP_me=$'\e[0m'
    export LESS_TERMCAP_se=$'\e[0m'
    export LESS_TERMCAP_so=$'\e[01;33m'
    export LESS_TERMCAP_ue=$'\e[0m'
    export LESS_TERMCAP_us=$'\e[1;4;31m'

    source ${localBin}/.bash_additions
    . ${gitAndTools.git}/share/bash-completion/completions/git
    . ${gitAndTools.git}/share/bash-completion/completions/git-prompt.sh
    __git_complete g __git_main

    # Docker
    function dl() {
      local id=$(${d} ps -qf "name=$1");
      ${d} logs -f $id;
    }

    # Shell
    function show_status_code() {
        case $? in
          0) echo '(:';;
          130) echo '(;';;
          *) echo 'D:';;
        esac
    }

    # Util
    function up() {
        ping 8.8.8.8 -c 1 | grep "[0-9]\+ bytes" | sed -e "s/.*time=\(.* ms\).*/\1/"
    }

    function notes {
      if ! [ -z "$1" ]; then
        ${v} -c 'set wrap' ~/.notes/$1
      else
        ${v} -c 'set wrap' ~/.notes
      fi
    }

    function reminder {
      sleep $1 && notify-send -u normal Reminder "''${2}" &
      disown
    }

    function tea {
      local steepTime
      if [[ "$1" == "green" ]]; then
        steepTime="90s"
      else
        steepTime="200s"
      fi
      reminder $steepTime "Remove tea leaves"
      reminder 14m "Perfect temperature tea is ready!"
    }

    function encrypt {
      ${zip}/bin/zip -e $1.zip $1
    }

    function json-diff {
      diff <(jq -S . $1) <(jq -S . $2)
    }

    function diff-csv {
      ${g} diff --no-index --word-diff-regex='[^,]+' $1 $2
    }
  '' + (configureExtraBashConfig { inherit pkgs stable-packages; });
}
