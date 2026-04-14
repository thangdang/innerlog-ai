import { Component, OnInit } from '@angular/core';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-insights',
  templateUrl: './insights.component.html',
})
export class InsightsComponent implements OnInit {
  insights: any[] = [];
  loading = true;

  constructor(private api: ApiService) {}

  ngOnInit() {
    this.api.getInsightHistory().subscribe({
      next: (data) => { this.insights = data; this.loading = false; },
      error: () => { this.loading = false; },
    });
  }
}
