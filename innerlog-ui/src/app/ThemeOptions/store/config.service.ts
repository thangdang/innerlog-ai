import { Injectable } from '@angular/core';
import { Store } from '@ngrx/store';
import { toggleSidebar } from './config.reducer.ngrx';

@Injectable({ providedIn: 'root' })
export class ConfigService {
  constructor(private store: Store) {}

  toggleSidebar() {
    this.store.dispatch(toggleSidebar());
  }
}
