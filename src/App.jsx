import { HashRouter, Routes, Route } from 'react-router-dom'
import Index from './pages/Index/Index'
import Add from './pages/Add/Add'
import Detail from './pages/Detail/Detail'
import './App.css'

function App() {
  return (
    <HashRouter>
      <Routes>
        <Route path="/" element={<Index />} />
        <Route path="/add" element={<Add />} />
        <Route path="/detail/:id" element={<Detail />} />
      </Routes>
    </HashRouter>
  )
}

export default App
