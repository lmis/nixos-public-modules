{ pkgs, stable-packages, homeManager, git }: with pkgs; {
  enable = true;

  userName = git.userName;
  userEmail = git.userEmail;

  attributes = [ "*.pdf diff=pdf" ];
  extraConfig = {
    commit.template = "${homeManager}/files/git-default-message";
    merge.tool = "meld";
    diff = {
      tool = "meld";
    }
    // (if git.sopsEnabled then {
      sops.textconv = "${sops}/bin/sops -d";
    } else { });
    difftool = {
      prompt = false;
      pdf.cmd = "${diff-pdf}/bin/diff-pdf \"$LOCAL\" \"$REMOTE\"";
      meld.cmd = "${meld}/bin/meld \"$LOCAL\" \"$REMOTE\"";
    };
    rerere.enabled = true; # Remember conflic resolutions for later re-application
    push.autoSetupRemote = true;
  };
  aliases = {
    # Status
    s = "!sh -c 'git status -bs && git l -n 5';";

    # Checkout
    co = "checkout";
    cob = "checkout -b";
    coi = "!sh -c 'git checkout $(${xclip}/bin/xclip -se clip -o)'";

    # Reset
    ruh = "reset --hard @{u}";
    ruhc = "!sh -c 'git reset --hard @{u} && git clean -id'";

    # Stage
    sp = "stage -up";
    su = "stage -u";

    # Commit
    c = "commit --verbose";
    ca = "commit --amend --verbose --date \"now\"";
    cano = "commit --amend --verbose --no-edit --date \"now\"";

    # Log
    l = "log -n 50 --decorate --graph --pretty=format:\"%C(auto)%<(75,trunc)%s\\ %Cgreen%<(15,trunc)%an\\ %C(auto)%h\\ %D%+N\"";
    rl = "reflog -n25";

    # Diff
    d = "diff";
    sh = "show -m";
    stat = "show --stat";
    st = "diff --staged";

    # Fetch, Pull, Push
    f = "fetch";
    p = "push";
    pf = "push --force-with-lease";
    pr = "pull --rebase --autostash";

    # Merge
    mt = "mergetool";
    mc = "merge --continue";

    # Cherry-pick
    cp = "cherry-pick";
    cpr = "!sh -c 'git cherry-pick @@{\"$0\"}'";
    cpa = "cherry-pick --abort";
    cc = "cherry-pick --continue";

    # Rebase
    r = "rebase";
    ri = "!sh -c 'git rebase -i @~\"$0\"'";
    rba = "rebase --abort";
    rc = "rebase --continue";

    # Stash
    sta = "stash";
  };
}
