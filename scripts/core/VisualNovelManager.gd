extends Node;

signal dialogue_started;
signal dialogue_finished;
signal choice_presented(choices: Array);
signal choice_made(choice_index: int);
signal scene_changed(scene_name: String);
signal character_shown(character_name: String, position: Vector2);
signal character_hidden(character_name: String);

var config = {
  "text_speed": 0.05, # seconds per character
  "auto_forward_time": 2.0, # seconds
  "skip_unread": false, # skip unread text when auto-forwarding
  "font_size": 24,
};