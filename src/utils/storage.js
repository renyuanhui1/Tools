const HABITS_KEY = 'habits'
const RECORDS_KEY = 'records'

export function getHabits() {
  try {
    const val = localStorage.getItem(HABITS_KEY)
    return val ? JSON.parse(val) : []
  } catch { return [] }
}

export function saveHabits(habits) {
  localStorage.setItem(HABITS_KEY, JSON.stringify(habits))
}

export function addHabit(habit) {
  const habits = getHabits()
  habit.id = Date.now().toString()
  habit.createdAt = new Date().toISOString()
  habits.push(habit)
  saveHabits(habits)
  return habit
}

export function deleteHabit(id) {
  saveHabits(getHabits().filter(h => h.id !== id))
  const records = getRecords()
  delete records[id]
  saveRecords(records)
}

export function getRecords() {
  try {
    const val = localStorage.getItem(RECORDS_KEY)
    return val ? JSON.parse(val) : {}
  } catch { return {} }
}

export function saveRecords(records) {
  localStorage.setItem(RECORDS_KEY, JSON.stringify(records))
}

export function todayStr() {
  return new Date().toISOString().slice(0, 10)
}

export function checkIn(habitId) {
  const records = getRecords()
  if (!records[habitId]) records[habitId] = []
  const today = todayStr()
  if (!records[habitId].includes(today)) {
    records[habitId].push(today)
    saveRecords(records)
  }
}

export function cancelCheckIn(habitId) {
  const records = getRecords()
  if (!records[habitId]) return
  records[habitId] = records[habitId].filter(d => d !== todayStr())
  saveRecords(records)
}

export function isCheckedToday(habitId) {
  return (getRecords()[habitId] || []).includes(todayStr())
}

export function getStreak(habitId) {
  const dates = (getRecords()[habitId] || []).sort()
  if (!dates.length) return 0
  let streak = 0
  const today = new Date(todayStr())
  for (let i = 0; i < 365; i++) {
    const d = new Date(today)
    d.setDate(d.getDate() - i)
    if (dates.includes(d.toISOString().slice(0, 10))) streak++
    else break
  }
  return streak
}

export function getMonthRecords(habitId, year, month) {
  const prefix = `${year}-${String(month).padStart(2, '0')}`
  return (getRecords()[habitId] || []).filter(d => d.startsWith(prefix))
}
