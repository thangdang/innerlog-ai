import { Component, OnInit } from '@angular/core';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-checkins',
  templateUrl: './checkins.component.html',
})
export class CheckinsComponent implements OnInit {
  checkins: any[] = [];
  loading = true;
  fromDate = '';
  toDate = '';

  constructor(private api: ApiService) {}

  ngOnInit() { this.loadCheckins(); }

  loadCheckins() {
    this.loading = true;
    this.api.getCheckins(this.fromDate || undefined, this.toDate || undefined).subscribe({
      next: (data) => {
        // Handle both paginated and array responses
        this.checkins = Array.isArray(data) ? data : (data.data || []);
        this.loading = false;
      },
      error: () => { this.loading = false; },
    });
  }

  clearFilter() {
    this.fromDate = '';
    this.toDate = '';
    this.loadCheckins();
  }

  moodEmoji(score: number): string {
    const emojis = ['', '😢', '😟', '😐', '🙂', '😄'];
    return emojis[score] || '😐';
  }
}
