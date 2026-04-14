import { Component, OnInit } from '@angular/core';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-goals',
  templateUrl: './goals.component.html',
})
export class GoalsComponent implements OnInit {
  goals: any[] = [];
  loading = true;

  constructor(private api: ApiService) {}

  ngOnInit() {
    this.api.getGoals().subscribe({
      next: (data) => { this.goals = data; this.loading = false; },
      error: () => { this.loading = false; },
    });
  }
}
