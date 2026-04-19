import { Component, OnInit } from '@angular/core';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-insights',
  templateUrl: './insights.component.html',
})
export class InsightsComponent implements OnInit {
  insights: any[] = [];
  loading = true;
  generating = false;
  selectedPeriod = '7d';

  constructor(private api: ApiService) {}

  ngOnInit() { this.loadInsights(); }

  loadInsights() {
    this.loading = true;
    this.api.getInsightHistory().subscribe({
      next: (data) => { this.insights = data; this.loading = false; },
      error: () => { this.loading = false; },
    });
  }

  generateInsight() {
    this.generating = true;
    this.api.generateInsight(this.selectedPeriod).subscribe({
      next: () => { this.generating = false; this.loadInsights(); },
      error: () => { this.generating = false; },
    });
  }
}
