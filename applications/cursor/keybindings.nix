# Generated from Cursor keybindings.json during migration to programs.vscode.
[
  {
    command = "editor.emmet.action.balanceIn";
    key = "shift+cmd+a";
  }
  {
    command = "editor.emmet.action.balanceOut";
    key = "alt+cmd+a";
  }
  {
    args = {
      text = "<br />";
    };
    command = "type";
    key = "shift+enter";
    when = "editorTextFocus && editorLangId == 'html'";
  }
  {
    command = "composerMode.agent";
    key = "cmd+i";
  }
  {
    args = {
      commands = [
        "workbench.files.action.showActiveFileInExplorer"
        "list.focusUp"
        "list.select"
      ];
    };
    command = "runCommands";
    key = "alt+cmd+up";
  }
  {
    args = {
      commands = [
        "workbench.files.action.showActiveFileInExplorer"
        "list.focusDown"
        "list.select"
      ];
    };
    command = "runCommands";
    key = "alt+cmd+down";
  }
]
