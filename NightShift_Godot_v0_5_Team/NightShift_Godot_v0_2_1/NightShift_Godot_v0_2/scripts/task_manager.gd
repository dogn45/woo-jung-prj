extends Node
class_name NSTaskManager
signal updated
var progress = {"stock": 0, "sale": 0, "trash": 0, "power": 0}
var goals = {"stock": 3, "sale": 1, "trash": 1, "power": 1}
var titles = {"stock": "창고 음료 3개 → 냉장고", "sale": "상품 스캔 → POS 결제", "trash": "창고 쓰레기 → 뒤편 쓰레기장", "power": "뒷골목 차단기 확인"}

func record(task: String, amount: int = 1) -> void:
	if progress.has(task):
		progress[task] = mini(goals[task], int(progress[task]) + amount)
		updated.emit()

func summary() -> String:
	var result = "오늘의 업무\n"
	for key in goals:
		result += "%s  %s   %d/%d\n" % ["✓" if progress[key] >= goals[key] else "○", titles[key], progress[key], goals[key]]
	return result
