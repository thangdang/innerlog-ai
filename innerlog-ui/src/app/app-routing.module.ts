import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { DashboardComponent } from './InnerLog/dashboard/dashboard.component';
import { UsersComponent } from './InnerLog/users/users.component';
import { CheckinsComponent } from './InnerLog/checkins/checkins.component';
import { InsightsComponent } from './InnerLog/insights/insights.component';
import { GoalsComponent } from './InnerLog/goals/goals.component';
import { LoginComponent } from './InnerLog/login/login.component';

const routes: Routes = [
  { path: '', redirectTo: '/innerlog/dashboard', pathMatch: 'full' },
  { path: 'innerlog/dashboard', component: DashboardComponent },
  { path: 'innerlog/users', component: UsersComponent },
  { path: 'innerlog/checkins', component: CheckinsComponent },
  { path: 'innerlog/insights', component: InsightsComponent },
  { path: 'innerlog/goals', component: GoalsComponent },
  { path: 'pages/login', component: LoginComponent },
  { path: '**', redirectTo: '' },
];

@NgModule({
  imports: [RouterModule.forRoot(routes, {
    scrollPositionRestoration: 'enabled',
    anchorScrolling: 'enabled',
  })],
  exports: [RouterModule],
})
export class AppRoutingModule {}
