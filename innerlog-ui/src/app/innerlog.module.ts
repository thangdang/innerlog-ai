import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgChartsModule } from 'ng2-charts';

import { DashboardComponent } from './InnerLog/dashboard/dashboard.component';
import { UsersComponent } from './InnerLog/users/users.component';
import { CheckinsComponent } from './InnerLog/checkins/checkins.component';
import { InsightsComponent } from './InnerLog/insights/insights.component';
import { GoalsComponent } from './InnerLog/goals/goals.component';
import { LoginComponent } from './InnerLog/login/login.component';

@NgModule({
  declarations: [
    DashboardComponent,
    UsersComponent,
    CheckinsComponent,
    InsightsComponent,
    GoalsComponent,
    LoginComponent,
  ],
  imports: [CommonModule, FormsModule, NgChartsModule],
  exports: [
    DashboardComponent,
    UsersComponent,
    CheckinsComponent,
    InsightsComponent,
    GoalsComponent,
    LoginComponent,
  ],
})
export class InnerLogModule {}
