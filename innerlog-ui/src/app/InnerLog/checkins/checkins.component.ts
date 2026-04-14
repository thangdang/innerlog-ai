import { Component, OnInit } from '@angular/core';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-checkins',
  templateUrl: './checkins.component.html',
})
export class CheckinsComponent implements OnInit {
  checkins: any[] = [];
  loading = true;

  constructor(private api: ApiService) {}

  ngOnInit() {
    this.api.getCheckins().subscribe({
      next: (data) => { this.checkins = data; this.loading = false; },
      error: () => { this.loading = false; },
    });
  }

  moodEmoji(score: number): string {
    const emojis = ['', '😢', '😟', '😐', '🙂', '😄'];
    return emojis[score] || '😐';
  }
}
