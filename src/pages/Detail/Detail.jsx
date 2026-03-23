import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { getHabits, deleteHabit, getMonthRecords, getStreak, isCheckedToday, checkIn, cancelCheckIn } from '../../utils/storage'
import './Detail.css'

export default function Detail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [habit, setHabit] = useState(null)
  const [year, setYear] = useState(new Date().getFullYear())
  const [month, setMonth] = useState(new Date().getMonth() + 1)
  const [, forceUpdate] = useState(0)

  useEffect(() => {
    const h = getHabits().find(x => x.id === id)
    setHabit(h)
  }, [id])

  function changeMonth(delta) {
    let m = month + delta, y = year
    if (m > 12) { m = 1; y++ }
    if (m < 1) { m = 12; y-- }
    setMonth(m); setYear(y)
  }

  function handleDelete() {
    if (window.confirm('删除后打卡记录也会清除，确定吗？')) {
      deleteHabit(id)
      navigate('/')
    }
  }

  function handleCheckIn() {
    if (isCheckedToday(id)) cancelCheckIn(id)
    else checkIn(id)
    forceUpdate(n => n + 1)
  }

  if (!habit) return <div className="loading">加载中...</div>

  const firstDay = new Date(year, month - 1, 1).getDay()
  const daysInMonth = new Date(year, month, 0).getDate()
  const cells = [...Array(firstDay).fill(null), ...Array.from({length: daysInMonth}, (_, i) => i + 1)]
  const checkedDates = getMonthRecords(id, year, month).map(d => parseInt(d.slice(8, 10)))
  const streak = getStreak(id)
  const checkedToday = isCheckedToday(id)
  const today = new Date()
  const isCurrentMonth = today.getFullYear() === year && today.getMonth() + 1 === month

  return (
    <div className="container">
      <div className="hero">
        <span className="hero-icon">{habit.icon}</span>
        <span className="hero-name">{habit.name}</span>
        {habit.desc && <span className="hero-desc">{habit.desc}</span>}
        <div className="stats">
          <div className="stat-item"><span className="stat-num">{streak}</span><span className="stat-label">连续天数</span></div>
          <div className="stat-item"><span className="stat-num">{getMonthRecords(id, year, month).length}</span><span className="stat-label">本月次数</span></div>
        </div>
      </div>

      <div className="calendar-section">
        <div className="cal-header">
          <span className="cal-arrow" onClick={() => changeMonth(-1)}>‹</span>
          <span className="cal-title">{year}年{month}月</span>
          <span className="cal-arrow" onClick={() => changeMonth(1)}>›</span>
        </div>
        <div className="cal-week">
          {['日','一','二','三','四','五','六'].map(w => <span key={w} className="week-label">{w}</span>)}
        </div>
        <div className="cal-grid">
          {cells.map((day, i) => (
            <div key={i} className={`cal-cell ${day && checkedDates.includes(day) ? 'checked' : ''} ${isCurrentMonth && day === today.getDate() ? 'today' : ''}`}>
              <span className="cal-day">{day || ''}</span>
            </div>
          ))}
        </div>
      </div>

      <button className={`btn-checkin ${checkedToday ? 'done' : ''}`} onClick={handleCheckIn}>
        {checkedToday ? '✓ 今日已打卡，点击取消' : '今日打卡'}
      </button>
      <button className="btn-delete" onClick={handleDelete}>删除此习惯</button>
    </div>
  )
}
