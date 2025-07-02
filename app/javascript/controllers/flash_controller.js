import { Controller } from "@hotwired/stimulus"
import Swal from "sweetalert2"

export default class extends Controller {
  connect() {
    const flashMessages = JSON.parse(this.element.dataset.flashMessages);
    if (flashMessages) {
      flashMessages.forEach(([type, message]) => {
        this.showToast(type, message);
      });
    }
  }

  showToast(type, message) {
    const Toast = Swal.mixin({
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 5000,
      timerProgressBar: true,
      didOpen: (toast) => {
        toast.addEventListener('mouseenter', Swal.stopTimer);
        toast.addEventListener('mouseleave', Swal.resumeTimer);
      }
    });

    let iconType = 'info';
    if (type === 'notice' || type === 'success') {
      iconType = 'success';
    } else if (type === 'alert' || type === 'error') {
      iconType = 'error';
    } else if (type === 'warning') {
      iconType = 'warning';
    }
    
    Toast.fire({
      icon: iconType,
      title: message
    });
  }
} 