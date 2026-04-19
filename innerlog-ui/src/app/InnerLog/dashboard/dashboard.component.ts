import { Component, OnInit } from '@angular/core';
import { ChartConfiguration, ChartData } from 'chart.js';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
})
export class DashboardComponent implements OnInit {
  stats: any = {};
  loading = true;
  streaks: any[] = [];

  // Chart data
  chartData: ChartData<'line'> = { labels: [], datasets: [] };
  chartOptions: ChartConfiguration<'line'>['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { position: 'top' } },
    scales: { y: { beginAtZero: true } },
  };

  constructor(private api: ApiService) {}

  ngOnInit() {
    this.api.getDashboard().subscribe({
      next: (data) => { this.stats = data; this.loading = false; },
      error: () => { this.loading = false; },
    });

    this.api.getDashboardChart(30).subscribe({
      next: (data) => {
        this.chartData = {
          labels: (data.labels || []).map((l: string) => l.substring(5)), // MM-DD
          datasets: [
            {
              label: 'Đăng ký',
              data: data.signups || [],
              borderColor: '#6C63FF',
              backgroundColor: 'rgba(108,99,255,0.1)',
              fill: true,
              tension: 0.3,
            },
            {
              label: 'Check-ins',
              data: data.checkins || [],
              borderColor: '#28a745',
              backgroundColor: 'rgba(40,167,69,0.1)',
              fill: true,
              tension: 0.3,
            },
          ],
        };
      },
    });

    this.api.getTopStreaks().subscribe({
      next: (data) => { this.streaks = (data || []).slice(0, 10); },
    });
  }
}
