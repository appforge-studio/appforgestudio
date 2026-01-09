library code_editor;

import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'ToolButton.dart';
import 'formatters/html.dart';

part 'EditorModel.dart';
part 'FileEditor.dart';
part 'EditorModelStyleOptions.dart';
part 'Theme.dart';

class CodeEditor extends StatefulWidget {
  /// The EditorModel in order to control the editor.
  late final EditorModel model;

  /// Background color for the code editor area.
  final Color backgroundColor;

  /// Border radius for the code editor area.
  final double borderRadius;

  /// Padding for the editable area.
  final EdgeInsetsGeometry padding;

  /// Function to execute when the user saves changes in a file.
  /// This is a function that takes [language] and [value] as arguments.
  ///
  /// - [language] is the language of the file edited by the user.
  /// - [value] is the content of the file.
  final void Function(String language, String value)? onSubmit;

  /// You can disable the navigation bar like this:
  ///
  /// ```
  /// CodeEditor(
  ///   disableNavigationbar: true, // hides the navigation bar
  /// )
  /// ```
  ///
  /// By default, the value is `false`.
  ///
  /// WARNING: if you set the value to `true`, only the first
  /// file will be displayed in the editor because
  /// it's not possible to switch between other files without the navigation bar.
  final bool disableNavigationbar;

  /// The list of languages that the editor is allowed to auto-format on save.
  /// As of now, only "html" is supported:
  ///
  /// ```
  /// CodeEditor(
  ///   formatters: const ["html"]
  /// )
  /// ```
  ///
  /// IMPORTANT: this is an experimental feature,
  /// there could be some edge cases that the auto-formatter doesn't handle.
  /// If you have issues with it, please consider reporting an issue on the GitHub repo.
  final List<String> formatters;

  /// A function you can call right before the modification of a file is applied.
  ///
  /// ### Note that it is called before the auto-formatting.
  ///
  /// Be aware that if you apply changes to any file of a particular language,
  /// and at the same time allow the auto-formatting of this same language,
  /// considering it is supported by the editor and allowed by you,
  /// then the result of your function might not be the exact output the file will receive
  ///
  /// ```
  /// CodeEditor(
  ///   model: model,
  ///   textModifier: (String language, String content) {
  ///     if (language == "html") {
  ///       // the content of any HTML file will become the return value
  ///       // when they are modified
  ///       return myCustomHTMLFormatter(content);
  ///     } else {
  ///       return content;
  ///     }
  ///   },
  /// )
  /// ```
  final String Function(String language, String content)? textModifier;

  /// Creates a code editor that helps users to write and read code on mobile.
  ///
  /// You can define:
  /// - [model] an `EditorModel`, to control the editor, its content and its files (required, if you don't want it, use `CodeEditor.empty()`)
  /// - [onSubmit] a `Function(String language, String value)` executed when the user submits changes in a file.
  /// - [textModifier] a `String Function(String language, String content)` that allows you to change the modifications of the user before it is saved.
  /// - [disableNavigationbar] if set to true, the navigation bar will be hidden. By default, it is false.
  /// - [formatters] the list of languages the editor is allowed to auto-format on save. As of now, only `html` is supported.
  ///
  /// ```
  /// CodeEditor(
  ///   model: myModel,
  /// ),
  /// ```
  CodeEditor({
    Key? key,
    required this.model,
    this.textModifier,
    this.onSubmit,
    this.disableNavigationbar = false,
    this.formatters = const [],
    this.backgroundColor = Colors.white,
    this.borderRadius = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  }) : super(key: key);

  /// Creates a code editor that helps users to write and read code on mobile.
  ///
  /// - [onSubmit] a `Function(String language, String value)` executed when the user submits changes in a file.
  /// - [textModifier] a `String Function(String language, String content)` that allows you to change the modifications of the user before it is saved.
  /// - [disableNavigationbar] if set to `true`, the navigation bar will be hidden. By default, it is `false`.
  /// - [formatters] the list of languages the editor is allowed to auto-format on save. As of now, only `html` is supported.
  CodeEditor.empty({
    Key? key,
    this.textModifier,
    this.disableNavigationbar = false,
    this.onSubmit,
    this.formatters = const [],
    this.backgroundColor = Colors.white,
    this.borderRadius = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  }) : super(key: key) {
    this.model = EditorModel();
  }

  @override
  _CodeEditorState createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  /// We need it to control the content of the text field.
  late TextEditingController editingController;

  /// The new content of a file when the user is editing one.
  String? newValue;

  /// The text field wants a focus node.
  FocusNode focusNode = FocusNode();

  /// Initialize the formKey for the text field
  static final GlobalKey<FormState> editableTextKey = GlobalKey<FormState>();

  // For each filename,
  // a stack of undos
  // and a stack of redos.
  // As the user does something in the application, we PUSH an action onto the undo stack.
  // If the user "undos" an action, we POP off the undo stack, do the operation, then we PUSH an action onto the redo stack
  // If the user undos multiple times, then does not redo but instead performs a unique action, we consider the redo stack lost
  Map<String, List<String>> undos = {};
  Map<String, List<String>> redos = {};

  @override
  void initState() {
    super.initState();

    // Initialize the controller for the text field with the code of the first file.
    editingController = TextEditingController(text: widget.model.getCodeWithIndex(0));

    newValue = ""; // if there are no changes

    // Init undos/redos stack with an empty array.
    // Each file has its own history.
    for (FileEditor file in widget.model.allFiles) {
      undos[file.name] = [];
      redos[file.name] = [];
    }
  }

  @override
  void dispose() {
    editingController.dispose();
    super.dispose();
  }

  void recordBeforeAction(FileEditor file) {
    undos[file.name]!.add(file.code);
    clearRedos(); // if the user edits an older version, the redo stack is lost
  }

  void clearRedos() {
    FileEditor editedFile = widget.model.getFileWithIndex(widget.model.position)!;
    redos[editedFile.name] = [];
  }

  void undo() {
    int currentPosition = widget.model.position;
    FileEditor editedFile = widget.model.getFileWithIndex(currentPosition)!;
    if (undos[editedFile.name]?.length != 0) {
      String previousState = undos[editedFile.name]!.removeLast();
      String currentState = editedFile.code;
      redos[editedFile.name]!.add(currentState);
      setState(() {
        widget.model.updateCodeOfIndex(currentPosition, previousState);
      });
    }
  }

  void redo() {
    int currentPosition = widget.model.position;
    FileEditor currentFile = widget.model.getFileWithIndex(currentPosition)!;
    if (redos[currentFile.name]?.length != 0) {
      undos[currentFile.name]!.add(currentFile.code);
      setState(() {
        widget.model.updateCodeOfIndex(currentPosition, redos[currentFile.name]!.removeLast());
      });
    }
  }

  /// Set the cursor at the end of the editableText.
  void placeCursorAtTheEnd() {
    editingController.selection = TextSelection.fromPosition(
      TextPosition(offset: editingController.text.length),
    );
  }

  /// Place the cursor where it's needed.
  ///
  /// - [pos] the index where to place the cursor in the text field
  void placeCursor(int pos) {
    try {
      editingController.selection = TextSelection.fromPosition(
        TextPosition(offset: pos),
      );
    } catch (e) {
      throw Exception("code_editor : placeCursor(int pos), pos is not valid.");
    }
  }

  /// Modifies a file according to its language to follow a precise format.
  String format(String content, String language) {
    switch (language) {
      case "html":
        return formatHTML(content);
      default:
        return content;
    }
  }

  /// The Text widget corresponding to the name of a file in the navigation bar.
  Text showFilename(String name, bool isSelected) {
    return Text(
      name,
      style: TextStyle(
        fontFamily: "monospace",
        letterSpacing: 1.0,
        fontWeight: FontWeight.normal,
        fontSize: widget.model.styleOptions.fontSizeOfFilename,
        color: isSelected ? widget.model.styleOptions.editorFilenameColor : widget.model.styleOptions.editorFilenameColor.withOpacity(0.5),
      ),
    );
  }

  /// Build the navigation bar.
  Container buildNavbar() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: widget.model.styleOptions.editorColor,
        border: Border(
          bottom: BorderSide(color: widget.model.styleOptions.editorBorderColor),
        ),
      ),
      child: ListView.builder(
        padding: EdgeInsets.only(left: 15),
        itemCount: widget.model.numberOfFiles,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, int index) {
          final FileEditor file = widget.model.getFileWithIndex(index)!;

          return Container(
            margin: EdgeInsets.only(right: 15),
            child: Center(
              child: GestureDetector(
                // Checks if the position of the navbar is the current file.
                child: showFilename(file.name, widget.model.position == index),
                onTap: () {
                  setState(() {
                    widget.model.changeIndexTo(index);
                    editingController.text = widget.model.getCodeWithIndex(index);
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Creates the text field.
  SingleChildScrollView buildEditableText() {
    return SingleChildScrollView(
      child: Container(
        padding: widget.padding,
        child: TextField(
          decoration: InputDecoration(border: InputBorder.none),
          autofocus: true,
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: null, // allow to grow as needed
          style: widget.model.styleOptions.textStyleOfTextField,
          focusNode: focusNode,
          controller: editingController,
          onChanged: (String v) => newValue = v,
          onTapOutside: (_) {
            if (widget.model.styleOptions.removeFocusOfTextFieldOnTapOutside) {
              // Because it's too annoying on IPhone
              if (focusNode.hasFocus) {
                focusNode.unfocus();
              }
            }
          },
          key: editableTextKey,
          toolbarOptions: widget.model.styleOptions.toolbarOptions,
        ),
      ),
    );
  }

  /// Creates the edit button and the save button ("OK") with a
  /// particular function to execute.
  ///
  /// This button won't appear if the current file is set as `readonly`.
  Widget editButton(String name, void Function() press) {
    if (widget.model.getFileWithIndex(widget.model.position)?.readonly == true) {
      return SizedBox.shrink();
    }
    final opt = widget.model.styleOptions;
    List<ElevatedButton> buttons = [];
    if (widget.model.styleOptions.showUndoRedoButtons) {
      ElevatedButton undoButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0.0,
          backgroundColor: Colors.white.withOpacity(0),
        ),
        child: FaIcon(
          FontAwesomeIcons.arrowCircleLeft,
          color: Colors.white.withOpacity(0.5),
          size: 18,
        ),
        onPressed: () {
          undo();
        },
      );
      ElevatedButton redoButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0.0,
          backgroundColor: Colors.white.withOpacity(0),
        ),
        child: FaIcon(
          FontAwesomeIcons.arrowCircleRight,
          color: Colors.white.withOpacity(0.5),
          size: 18,
        ),
        onPressed: () {
          redo();
        },
      );
      if (opt.reverseEditAndUndoRedoButtons) {
        // it will get reversed afterwards
        // so that it's always `undoButton` before `redoButton`
        buttons.addAll([redoButton, undoButton]);
      } else {
        buttons.addAll([undoButton, redoButton]);
      }
    }
    buttons.add(ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: opt.editButtonBackgroundColor,
      ),
      onPressed: press,
      child: Text(
        name,
        style: TextStyle(
          fontSize: 16.0,
          fontFamily: "monospace",
          fontWeight: FontWeight.normal,
          color: opt.editButtonTextColor,
        ),
      ),
    ));
    // if the user allowed modifications:
    return Positioned(
      bottom: opt.editButtonPosBottom,
      right: opt.editButtonPosRight,
      top: (widget.model.isEditing && opt.editButtonPosTop != null && opt.editButtonPosTop! < 50) ? 50 : opt.editButtonPosTop,
      left: opt.editButtonPosLeft,
      child: Row(
        children: opt.reverseEditAndUndoRedoButtons ? buttons.reversed.toList() : buttons,
      ),
    );
  }

  /// Add a particular string where the cursor is in the text field.
  /// - [str] the string to insert
  /// - [diff] by default, the cursor is placed after the placed string, but you can change this (example: -1 when quotes are placed in order to have the cursor at the center of the quotes)
  void insertIntoTextField(String str, {int diff = 0}) {
    // get the position of the cursor in the text field
    int pos = editingController.selection.baseOffset;
    // get the current text of the text field
    String baseText = editingController.text;
    // get the string: 0 -> pos of the current text and add the wanted string
    String begin = baseText.substring(0, pos) + str;
    // if we are already in the end of the string
    if (baseText.length == pos) {
      editingController.text = begin;
    } else {
      // get the end of the string and update the text of the text field
      String end = baseText.substring(pos, baseText.length);
      editingController.text = begin + end;
    }
    // if we don't do this, when we click on a toolbutton, the method
    // onChanged() isn't called, so newValue isn't updated
    newValue = editingController.text;
    placeCursor(pos + str.length + diff);
  }

  @override
  Widget build(BuildContext context) {
    /// Gets the style options from the parent widget.
    final EditorModelStyleOptions opt = widget.model.styleOptions;

    /// Which file in the list of file?
    final int position = widget.model.position;

    /// The content of the file where position corresponds to the list of file.
    final String? code = widget.model.getCodeWithIndex(position);

    // if the user does not change the value in the text field
    newValue = code;

    /// Creates the toolbar.
    // final List<ToolButton> toolButtons = [ ... ];
    // Widget toolBar() { ... }
    // (Remove the entire toolBar function and its usages)

    // We place the cursor in the end of the text field.
    if (widget.model.styleOptions.placeCursorAtTheEndOnEdit) {
      placeCursorAtTheEnd();
    }

    /// We toggle the editor and the text field.
    Widget buildContentEditor() {
      // Always show the editing UI, remove isEditing/view-only logic
      return Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                child: buildEditableText(),
              ),
            ],
          ),
          // OK button removed
        ],
      );
    }

    return Column(
      children: <Widget>[
        // Removed the filename header/navbar
        buildContentEditor(),
      ],
    );
  }
}
