import { Component, OnInit } from '@angular/core';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
})
export class DashboardComponent implements OnInit {
  stats: any = {};
  loading = true;

  constructor(private api: ApiService) {}

  ngOnInit() {
    this.api.getDashboard().subscribe({
      next: (data) => { this.stats = data; this.loading = false; },
      error: () => { this.loading = false; },
    });
  }
}
