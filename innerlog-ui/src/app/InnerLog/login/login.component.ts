import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
})
export class LoginComponent {
  email = '';
  password = '';
  error = '';

  constructor(private api: ApiService, private router: Router) {}

  login() {
    this.error = '';
    this.api.login(this.email, this.password).subscribe({
      next: (res) => {
        localStorage.setItem('token', res.token);
        localStorage.setItem('refreshToken', res.refreshToken);
        this.router.navigate(['/innerlog/dashboard']);
      },
      error: (err) => { this.error = err.error?.error || 'Đăng nhập thất bại'; },
    });
  }
}
