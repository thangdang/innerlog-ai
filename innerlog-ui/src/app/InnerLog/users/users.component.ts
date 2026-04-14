import { Component, OnInit } from '@angular/core';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-users',
  templateUrl: './users.component.html',
})
export class UsersComponent implements OnInit {
  users: any[] = [];
  total = 0;
  page = 1;
  loading = true;

  constructor(private api: ApiService) {}

  ngOnInit() { this.loadUsers(); }

  loadUsers() {
    this.loading = true;
    this.api.getUsers(this.page).subscribe({
      next: (data) => { this.users = data.users; this.total = data.total; this.loading = false; },
      error: () => { this.loading = false; },
    });
  }

  nextPage() { this.page++; this.loadUsers(); }
  prevPage() { if (this.page > 1) { this.page--; this.loadUsers(); } }
}
