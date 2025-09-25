import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (window.innerWidth <= 991 && !localStorage.getItem('mobile-tutorial-shown')) {
      this.showTutorial()
    }
  }

  showTutorial() {
    // Crear el overlay y el contenido del tutorial
    const overlay = document.createElement('div')
    overlay.className = 'mobile-tutorial-overlay'
    overlay.innerHTML = `
      <div class="mobile-tutorial-content">
        <h5>¡Bienvenido a Cotalo!</h5>
        <p>Para navegar fácilmente:</p>
        <ul>
          <li>Toca el logo para volver al inicio</li>
          <li>Usa el botón "Menú" para acceder a todas las opciones</li>
        </ul>
        <button class="btn btn-success">Entendido</button>
      </div>
    `

    // Agregar estilos
    const style = document.createElement('style')
    style.textContent = `
      .mobile-tutorial-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.8);
        z-index: 9999;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 20px;
      }
      .mobile-tutorial-content {
        background: var(--dark-bg);
        padding: 20px;
        border-radius: 10px;
        max-width: 300px;
        text-align: center;
        border: 1px solid var(--cotalo-green);
      }
      .mobile-tutorial-content h5 {
        color: var(--cotalo-green);
        margin-bottom: 15px;
      }
      .mobile-tutorial-content ul {
        text-align: left;
        margin: 15px 0;
        padding-left: 20px;
      }
      .mobile-tutorial-content li {
        margin: 10px 0;
        color: #fff;
      }
      .mobile-tutorial-content button {
        margin-top: 10px;
      }
    `

    // Agregar al DOM
    document.head.appendChild(style)
    document.body.appendChild(overlay)

    // Manejar el cierre
    const button = overlay.querySelector('button')
    button.addEventListener('click', () => {
      overlay.remove()
      localStorage.setItem('mobile-tutorial-shown', 'true')
    })
  }
}
