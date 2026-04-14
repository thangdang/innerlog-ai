import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private base = environment.apiUrl;

  constructor(private http: HttpClient) {}

  private authHeaders(): HttpHeaders {
    const token = localStorage.getItem('token');
    return new HttpHeaders(token ? { Authorization: `Bearer ${token}` } : {});
  }

  // Auth
  login(email: string, password: string): Observable<any> {
    return this.http.post(`${this.base}/auth/login`, { email, password });
  }

  register(email: string, password: string, name: string): Observable<any> {
    return this.http.post(`${this.base}/auth/register`, { email, password, display_name: name });
  }

  getMe(): Observable<any> {
    return this.http.get(`${this.base}/auth/me`, { headers: this.authHeaders() });
  }

  // Dashboard
  getDashboard(): Observable<any> {
    return this.http.get(`${this.base}/dashboard`, { headers: this.authHeaders() });
  }

  getUsers(page = 1, limit = 20, plan?: string): Observable<any> {
    let params: any = { page, limit };
    if (plan) params.plan = plan;
    return this.http.get(`${this.base}/dashboard/users`, { params, headers: this.authHeaders() });
  }

  // Check-ins
  getCheckins(from?: string, to?: string): Observable<any> {
    let params: any = {};
    if (from) params.from = from;
    if (to) params.to = to;
    return this.http.get(`${this.base}/checkins`, { params, headers: this.authHeaders() });
  }

  // Insights
  getInsightHistory(period?: string): Observable<any> {
    let params: any = {};
    if (period) params.period = period;
    return this.http.get(`${this.base}/insights/history`, { params, headers: this.authHeaders() });
  }

  getLatestInsight(): Observable<any> {
    return this.http.get(`${this.base}/insights/latest`, { headers: this.authHeaders() });
  }

  generateInsight(period: string): Observable<any> {
    return this.http.post(`${this.base}/insights/generate`, { period }, { headers: this.authHeaders() });
  }

  // Goals
  getGoals(status?: string): Observable<any> {
    let params: any = {};
    if (status) params.status = status;
    return this.http.get(`${this.base}/goals`, { params, headers: this.authHeaders() });
  }

  // Dashboard Charts
  getDashboardChart(days = 30): Observable<any> {
    return this.http.get(`${this.base}/dashboard/chart`, { params: { days }, headers: this.authHeaders() });
  }

  getTopStreaks(): Observable<any> {
    return this.http.get(`${this.base}/dashboard/streaks`, { headers: this.authHeaders() });
  }

  // Notifications
  getNotifications(unread = false): Observable<any> {
    return this.http.get(`${this.base}/notifications`, { params: { unread: unread ? 'true' : '' }, headers: this.authHeaders() });
  }
}
