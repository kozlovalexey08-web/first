extends Node2D

const CHALLENGE_LABELS := {
	"explain": "Объясни словами",
	"show": "Покажи без слов",
	"draw": "Нарисуй",
	"yes_no": "Только да/нет"
}

var points_to_win := 5
var turn_duration := 45.0
var teams := [
	{"name": "Команда 1", "score": 0},
	{"name": "Команда 2", "score": 0}
]
var deck := [
	{"word": "Пицца", "type": "explain", "hint": "Горячая, круглая, с кусочками."},
	{"word": "Кот", "type": "show", "hint": "Покажи животное без звуков."},
	{"word": "Самолёт", "type": "draw", "hint": "Нарисуй быстро и схематично."},
	{"word": "Дождь", "type": "yes_no", "hint": "Команда задаёт вопросы, ты отвечаешь только да или нет."},
	{"word": "Холодильник", "type": "explain", "hint": "Стоит на кухне и охлаждает."},
	{"word": "Футбол", "type": "show", "hint": "Покажи движение или игровую сцену."},
	{"word": "Замок", "type": "draw", "hint": "Башни, стены, ворота."},
	{"word": "Робот", "type": "yes_no", "hint": "Пусть команда угадывает через вопросы."},
	{"word": "Арбуз", "type": "explain", "hint": "Большой, зелёный, сладкий."},
	{"word": "Зонт", "type": "show", "hint": "Покажи предмет и как им пользоваться."}
]

var draw_pile := []
var current_card := {}
var active_team_index := 0
var round_number := 0
var time_left := 0.0
var round_running := false
var game_finished := false
var message := ""

var title_label: Label
var round_label: Label
var team_label: Label
var timer_label: Label
var mode_label: Label
var word_label: Label
var hint_label: Label
var score_label: Label
var message_label: Label
var start_button: Button
var success_button: Button
var fail_button: Button
var skip_button: Button
var restart_button: Button


func _ready() -> void:
	randomize()
	draw_pile = deck.duplicate(true)
	build_ui()
	render_ui()


func _process(delta: float) -> void:
	if not round_running or game_finished:
		return

	time_left = maxf(0.0, time_left - delta)
	if time_left <= 0.0:
		end_turn("Время вышло. Ход переходит следующей команде.")

	render_ui()


func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color("161d2a")
	root.add_child(background)

	var content := MarginContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 48)
	content.add_theme_constant_override("margin_top", 36)
	content.add_theme_constant_override("margin_right", 48)
	content.add_theme_constant_override("margin_bottom", 36)
	root.add_child(content)

	var main_layout := VBoxContainer.new()
	main_layout.add_theme_constant_override("separation", 18)
	content.add_child(main_layout)

	var top_panel := make_panel(Color("2b3142"))
	main_layout.add_child(top_panel)
	top_panel.custom_minimum_size = Vector2(0, 120)

	var top_margin := MarginContainer.new()
	top_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_margin.add_theme_constant_override("margin_left", 20)
	top_margin.add_theme_constant_override("margin_top", 16)
	top_margin.add_theme_constant_override("margin_right", 20)
	top_margin.add_theme_constant_override("margin_bottom", 16)
	top_panel.add_child(top_margin)

	var top_layout := HBoxContainer.new()
	top_layout.add_theme_constant_override("separation", 16)
	top_margin.add_child(top_layout)

	var left_info := VBoxContainer.new()
	left_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_layout.add_child(left_info)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 36)
	left_info.add_child(title_label)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 32)
	left_info.add_child(meta_row)

	round_label = Label.new()
	round_label.add_theme_font_size_override("font_size", 22)
	meta_row.add_child(round_label)

	team_label = Label.new()
	team_label.add_theme_font_size_override("font_size", 22)
	meta_row.add_child(team_label)

	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 34)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_layout.add_child(timer_label)

	var card_panel := make_panel(Color("efe0a9"))
	card_panel.custom_minimum_size = Vector2(0, 320)
	main_layout.add_child(card_panel)

	var card_margin := MarginContainer.new()
	card_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_margin.add_theme_constant_override("margin_left", 24)
	card_margin.add_theme_constant_override("margin_top", 18)
	card_margin.add_theme_constant_override("margin_right", 24)
	card_margin.add_theme_constant_override("margin_bottom", 18)
	card_panel.add_child(card_margin)

	var card_layout := VBoxContainer.new()
	card_layout.add_theme_constant_override("separation", 18)
	card_margin.add_child(card_layout)

	mode_label = Label.new()
	mode_label.add_theme_font_size_override("font_size", 24)
	mode_label.modulate = Color("4e3418")
	card_layout.add_child(mode_label)

	word_label = Label.new()
	word_label.add_theme_font_size_override("font_size", 52)
	word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	word_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_layout.add_child(word_label)

	hint_label = Label.new()
	hint_label.add_theme_font_size_override("font_size", 22)
	hint_label.modulate = Color("7b664c")
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_layout.add_child(hint_label)

	var bottom_panel := make_panel(Color("2b3142"))
	bottom_panel.custom_minimum_size = Vector2(0, 180)
	main_layout.add_child(bottom_panel)

	var bottom_margin := MarginContainer.new()
	bottom_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	bottom_margin.add_theme_constant_override("margin_left", 20)
	bottom_margin.add_theme_constant_override("margin_top", 16)
	bottom_margin.add_theme_constant_override("margin_right", 20)
	bottom_margin.add_theme_constant_override("margin_bottom", 16)
	bottom_panel.add_child(bottom_margin)

	var bottom_layout := VBoxContainer.new()
	bottom_layout.add_theme_constant_override("separation", 12)
	bottom_margin.add_child(bottom_layout)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_layout.add_child(score_label)

	var buttons_row := HBoxContainer.new()
	buttons_row.add_theme_constant_override("separation", 16)
	bottom_layout.add_child(buttons_row)

	start_button = make_button("Старт", Callable(self, "start_game"))
	buttons_row.add_child(start_button)

	success_button = make_button("Угадали", Callable(self, "mark_success"))
	buttons_row.add_child(success_button)

	fail_button = make_button("Не угадали", Callable(self, "mark_fail"))
	buttons_row.add_child(fail_button)

	skip_button = make_button("Сменить", Callable(self, "skip_card"))
	buttons_row.add_child(skip_button)

	restart_button = make_button("Заново", Callable(self, "restart_game"))
	buttons_row.add_child(restart_button)

	message_label = Label.new()
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.modulate = Color("c9e2ff")
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_layout.add_child(message_label)


func make_panel(color: Color) -> Panel:
	var panel := Panel.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel


func make_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color("b83b14")
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.corner_radius_bottom_left = 8

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color("d04a1c")

	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = Color("8f2c0e")

	var disabled_style := normal_style.duplicate()
	disabled_style.bg_color = Color("5b362c")

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("d0c1bb"))
	return button


func render_ui() -> void:
	title_label.text = "Экивоки: прототип"
	round_label.text = "Раунд: %d" % round_number
	team_label.text = "Ход: %s" % teams[active_team_index]["name"]
	timer_label.text = "Таймер: %d" % int(ceil(time_left))
	score_label.text = build_score_text()
	message_label.text = message

	if current_card.is_empty():
		mode_label.text = "Режим: Нажми старт"
		word_label.text = "Карточка появится после старта"
		hint_label.text = "Подсказка появится вместе с карточкой"
	else:
		mode_label.text = "Режим: %s" % CHALLENGE_LABELS.get(current_card["type"], "Задание")
		word_label.text = current_card["word"]
		hint_label.text = "Подсказка ведущему: %s" % current_card["hint"]

	start_button.visible = not round_running and not game_finished
	success_button.disabled = not round_running
	fail_button.disabled = not round_running
	skip_button.disabled = not round_running
	restart_button.visible = game_finished


func start_game() -> void:
	round_number = 1
	active_team_index = 0
	game_finished = false
	for team in teams:
		team["score"] = 0
	reset_deck()
	start_turn("Игра началась. Первая команда ходит.")


func restart_game() -> void:
	start_game()


func start_turn(new_message: String) -> void:
	if draw_pile.is_empty():
		reset_deck()

	current_card = draw_random_card()
	time_left = turn_duration
	round_running = true
	message = new_message
	render_ui()


func end_turn(new_message: String) -> void:
	round_running = false
	advance_team()
	start_turn(new_message)


func mark_success() -> void:
	if not round_running or game_finished:
		return

	teams[active_team_index]["score"] += 1
	if teams[active_team_index]["score"] >= points_to_win:
		round_running = false
		game_finished = true
		message = "Победила %s" % teams[active_team_index]["name"]
		render_ui()
		return

	end_turn("%s получает 1 очко." % teams[active_team_index]["name"])


func mark_fail() -> void:
	if not round_running or game_finished:
		return

	end_turn("Карточка не угадана.")


func skip_card() -> void:
	if not round_running or game_finished:
		return

	if draw_pile.is_empty():
		reset_deck()

	current_card = draw_random_card()
	message = "Новая карточка для %s." % teams[active_team_index]["name"]
	render_ui()


func advance_team() -> void:
	active_team_index = (active_team_index + 1) % teams.size()
	if active_team_index == 0:
		round_number += 1


func draw_random_card() -> Dictionary:
	var index := randi_range(0, draw_pile.size() - 1)
	var card: Dictionary = draw_pile[index]
	draw_pile.remove_at(index)
	return card


func reset_deck() -> void:
	draw_pile = deck.duplicate(true)


func build_score_text() -> String:
	var parts := []
	for team in teams:
		parts.append("%s: %d" % [team["name"], team["score"]])
	return "Счёт  " + "   |   ".join(parts)
