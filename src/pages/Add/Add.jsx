import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { addHabit } from '../../utils/storage'
import './Add.css'

const ICONS = ['🏃','📚','💧','🧘','💪','🎨','✍️','🎵','🥗','😴','🚴','🧹','💊','🌿','🙏','📝','🎯','🌅']

export default function Add() {
  const [name, setName] = useState('')
  const [icon, setIcon] = useState('🏃')
  const [desc, setDesc] = useState('')
  const navigate = useNavigate()

  function handleSave() {
    if (!name.trim()) { alert('请输入习惯名称'); return }
    addHabit({ name: name.trim(), icon, desc: desc.trim() })
    navigate('/')
  }

  return (
    <div className="container">
      <div className="section">
        <label className="label">习惯名称</label>
        <input className="input" placeholder="例如：每天读书30分钟" value={name}
          onChange={e => setName(e.target.value)} maxLength={20} />
      </div>
      <div className="section">
        <label className="label">选择图标</label>
        <div className="icon-grid">
          {ICONS.map(ic => (
            <div key={ic} className={`icon-item ${icon === ic ? 'selected' : ''}`} onClick={() => setIcon(ic)}>
              {ic}
            </div>
          ))}
        </div>
      </div>
      <div className="section">
        <label className="label">备注（可选）</label>
        <input className="input" placeholder="添加备注说明..." value={desc}
          onChange={e => setDesc(e.target.value)} maxLength={50} />
      </div>
      <button className="btn-save" onClick={handleSave}>保存习惯</button>
    </div>
  )
}
