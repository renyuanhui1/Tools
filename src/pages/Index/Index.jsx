import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { getHabits, checkIn, cancelCheckIn, isCheckedToday, getStreak } from '../../utils/storage'
import './Index.css'

export default function Index() {
  const [habits, setHabits] = useState([])
  const navigate = useNavigate()

  useEffect(() => { setHabits(getHabits()) }, [])

  function handleCheckIn(habit) {
    if (isCheckedToday(habit.id)) cancelCheckIn(habit.id)
    else checkIn(habit.id)
    setHabits([...getHabits()])
  }

  const today = new Date().toLocaleDateString('zh-CN', { month: 'long', day: 'numeric', weekday: 'long' })

  return (
    <div className="container">
      <div className="header">
        <span className="date">{today}</span>
        <span className="subtitle">坚持，是最好的习惯</span>
      </div>
      {habits.length === 0 ? (
        <div className="empty">
          <span className="empty-icon">🌱</span>
          <span className="empty-text">还没有习惯，去添加一个吧</span>
          <button className="btn-add" onClick={() => navigate('/add')}>+ 添加习惯</button>
        </div>
      ) : (
        <div className="list">
          {habits.map(habit => {
            const checked = isCheckedToday(habit.id)
            const streak = getStreak(habit.id)
            return (
              <div key={habit.id} className={`habit-card ${checked ? 'checked' : ''}`}>
                <div className="habit-left" onClick={() => navigate(`/detail/${habit.id}`)}>
                  <span className="habit-icon">{habit.icon}</span>
                  <div className="habit-info">
                    <span className="habit-name">{habit.name}</span>
                    <span className="habit-streak">🔥 连续 {streak} 天</span>
                  </div>
                </div>
                <button className={`checkin-btn ${checked ? 'done' : ''}`} onClick={() => handleCheckIn(habit)}>
                  {checked ? '✓ 已打卡' : '打卡'}
                </button>
              </div>
            )
          })}
          <button className="btn-add-float" onClick={() => navigate('/add')}>+</button>
        </div>
      )}
    </div>
  )
}
