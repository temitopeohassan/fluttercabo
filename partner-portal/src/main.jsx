import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { initStore } from './api/store'
import App from './App.jsx'
import './styles.css'

await initStore()

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
