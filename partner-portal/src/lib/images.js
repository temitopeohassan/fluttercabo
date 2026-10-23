/** Shrinks an uploaded photo to at most 1200 px wide as a JPEG data URL, so it fits in browser storage. */
export function resizeImage(file, maxWidth = 1200, quality = 0.78) {
  return new Promise((resolve, reject) => {
    if (!file.type.startsWith('image/')) return reject(new Error('Choose a JPG or PNG photo.'))
    if (file.size > 15 * 1024 * 1024) return reject(new Error('Photos must be under 15 MB.'))
    const url = URL.createObjectURL(file)
    const img = new Image()
    img.onload = () => {
      const scale = Math.min(1, maxWidth / img.width)
      const canvas = document.createElement('canvas')
      canvas.width = Math.round(img.width * scale)
      canvas.height = Math.round(img.height * scale)
      canvas.getContext('2d').drawImage(img, 0, 0, canvas.width, canvas.height)
      URL.revokeObjectURL(url)
      if (img.width < 800) return reject(new Error('Photos need to be at least 800 pixels wide to look sharp in the app.'))
      resolve(canvas.toDataURL('image/jpeg', quality))
    }
    img.onerror = () => {
      URL.revokeObjectURL(url)
      reject(new Error('That file could not be read as a photo.'))
    }
    img.src = url
  })
}
