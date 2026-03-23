const { app, BrowserWindow, protocol, Menu } = require('electron')
const path = require('path')

app.on('ready', () => {
  protocol.registerFileProtocol('file', (request, callback) => {
    const filePath = request.url.replace('file:///', '')
    callback(decodeURIComponent(filePath))
  })
})

function createWindow() {
  Menu.setApplicationMenu(null)
  const win = new BrowserWindow({
    width: 480,
    height: 800,
    resizable: true,
    title: '习惯打卡',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      webSecurity: false,
      allowRunningInsecureContent: true
    }
  })

  if (process.env.NODE_ENV === 'development') {
    win.loadURL('http://localhost:5173')
  } else {
    win.loadFile(path.join(app.getAppPath(), 'dist', 'index.html'))
  }
}

app.whenReady().then(createWindow)

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow()
})
