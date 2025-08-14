class TeamDashboard {
    constructor(options = {}) {
        this.containerId = options.containerId || 'dashboard-container';
        this.refreshInterval = options.refreshInterval || 300000; // 5 minutes
        this.charts = {};
        this.refreshTimer = null;
        
        this.init();
    }
    
    async init() {
        await this.loadDashboard();
        this.startAutoRefresh();
    }
    
    async loadDashboard() {
        const container = document.getElementById(this.containerId);
        if (!container) return;
        
        AgileUtils.showLoading(container);
        
        try {
            const [sprintData, teamData] = await Promise.all([
                this.fetchLatestSprintData(),
                this.fetchTeamMetrics()
            ]);
            
            this.render(sprintData, teamData);
        } catch (error) {
            console.error('Failed to load dashboard:', error);
            AgileUtils.showError(container, 'ダッシュボードの読み込みに失敗しました');
        }
    }
    
    async fetchLatestSprintData() {
        const sprints = await AgileUtils.getAvailableSprints();
        if (sprints.length === 0) return null;
        return AgileUtils.fetchSprintData(sprints[0]);
    }
    
    async fetchTeamMetrics() {
        try {
            const response = await fetch('../team-metrics.json');
            if (!response.ok) return this.generateMockTeamData();
            return await response.json();
        } catch {
            return this.generateMockTeamData();
        }
    }
    
    generateMockTeamData() {
        return {
            updated_at: new Date().toISOString(),
            team_members: [
                {
                    username: 'developer1',
                    avatar_url: null,
                    active_issues: 3,
                    completed_points: 8,
                    status: 'active'
                },
                {
                    username: 'developer2',
                    avatar_url: null,
                    active_issues: 2,
                    completed_points: 5,
                    status: 'active'
                }
            ],
            issues_by_type: {
                'user-story': 5,
                'task': 8,
                'bug': 3
            },
            issues_by_priority: {
                'high': 4,
                'medium': 7,
                'low': 5
            },
            velocity_trend: [
                { week: 'Week 1', velocity: 15 },
                { week: 'Week 2', velocity: 18 },
                { week: 'Week 3', velocity: 20 },
                { week: 'Week 4', velocity: 17 }
            ]
        };
    }
    
    render(sprintData, teamData) {
        const container = document.getElementById(this.containerId);
        container.innerHTML = '';
        
        const grid = AgileUtils.createElement('div', 'grid grid--responsive');
        
        if (sprintData) {
            grid.appendChild(this.createSprintOverview(sprintData));
            grid.appendChild(this.createMinieBurndown(sprintData));
        }
        
        grid.appendChild(this.createTeamMetrics(teamData));
        grid.appendChild(this.createIssueDistribution(teamData));
        grid.appendChild(this.createTeamMembers(teamData));
        grid.appendChild(this.createVelocityTrend(teamData));
        grid.appendChild(this.createQuickActions());
        
        container.appendChild(grid);
        
        if (teamData.updated_at) {
            const footer = AgileUtils.createElement('div', 'text-center text-muted mt-3');
            footer.textContent = `最終更新: ${AgileUtils.formatDateTime(teamData.updated_at)}`;
            container.appendChild(footer);
        }
    }
    
    createSprintOverview(data) {
        const card = AgileUtils.createElement('div', 'card');
        card.innerHTML = `<h3>📊 Sprint Overview</h3>`;
        
        const latestData = data.daily_data[data.daily_data.length - 1];
        if (!latestData) return card;
        
        const content = AgileUtils.createElement('div');
        
        const metrics = [
            { label: 'Sprint', value: data.milestone.title },
            { label: '進捗', value: `${latestData.completed_points}/${latestData.total_points} points` },
            { label: '完了率', value: `${AgileUtils.calculatePercentage(latestData.completed_points, latestData.total_points)}%` },
            { label: '残り日数', value: this.calculateRemainingDays(data.milestone.due_on) }
        ];
        
        metrics.forEach(metric => {
            const row = AgileUtils.createElement('div', 'metric');
            row.innerHTML = `
                <span class="metric-label">${metric.label}</span>
                <span class="metric-value">${metric.value}</span>
            `;
            content.appendChild(row);
        });
        
        card.appendChild(content);
        return card;
    }
    
    createMinieBurndown(data) {
        const card = AgileUtils.createElement('div', 'card');
        card.innerHTML = `<h3>🔥 Burndown Trend</h3>`;
        
        const chartContainer = AgileUtils.createElement('div', 'chart-container');
        chartContainer.style.height = '200px';
        const canvas = AgileUtils.createElement('canvas');
        canvas.id = 'mini-burndown-chart';
        chartContainer.appendChild(canvas);
        card.appendChild(chartContainer);
        
        setTimeout(() => this.drawMiniBurndown(data), 100);
        
        return card;
    }
    
    drawMiniBurndown(data) {
        const labels = data.daily_data.slice(-7).map(d => {
            const date = new Date(d.date);
            return `${date.getMonth() + 1}/${date.getDate()}`;
        });
        
        const remainingPoints = data.daily_data.slice(-7).map(d => d.remaining_points);
        
        const config = {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    label: '残りポイント',
                    data: remainingPoints,
                    borderColor: 'var(--color-danger)',
                    backgroundColor: 'rgba(215, 58, 74, 0.1)',
                    tension: 0.3,
                    fill: true
                }]
            },
            options: {
                ...AgileUtils.getDefaultChartOptions(),
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: {
                            display: false
                        }
                    },
                    x: {
                        grid: {
                            display: false
                        }
                    }
                }
            }
        };
        
        this.charts.miniBurndown = AgileUtils.initChart('mini-burndown-chart', config);
    }
    
    createTeamMetrics(data) {
        const card = AgileUtils.createElement('div', 'card');
        card.innerHTML = `<h3>📈 Team Metrics</h3>`;
        
        const metrics = this.calculateTeamMetrics(data);
        const content = AgileUtils.createElement('div');
        
        Object.entries(metrics).forEach(([label, value]) => {
            const row = AgileUtils.createElement('div', 'metric');
            row.innerHTML = `
                <span class="metric-label">${label}</span>
                <span class="metric-value">${value}</span>
            `;
            content.appendChild(row);
        });
        
        card.appendChild(content);
        return card;
    }
    
    calculateTeamMetrics(data) {
        const totalIssues = Object.values(data.issues_by_type || {}).reduce((a, b) => a + b, 0);
        const avgVelocity = data.velocity_trend ? 
            (data.velocity_trend.reduce((a, b) => a + b.velocity, 0) / data.velocity_trend.length).toFixed(1) : 0;
        
        return {
            'Active Issues': totalIssues,
            'Team Members': data.team_members?.length || 0,
            'Avg Velocity': `${avgVelocity} pts/week`,
            'Cycle Time': '3.2 days'
        };
    }
    
    createIssueDistribution(data) {
        const card = AgileUtils.createElement('div', 'card');
        card.innerHTML = `<h3>📋 Issue Distribution</h3>`;
        
        const chartContainer = AgileUtils.createElement('div', 'chart-container');
        chartContainer.style.height = '200px';
        const canvas = AgileUtils.createElement('canvas');
        canvas.id = 'issue-distribution-chart';
        chartContainer.appendChild(canvas);
        card.appendChild(chartContainer);
        
        setTimeout(() => this.drawIssueDistribution(data), 100);
        
        return card;
    }
    
    drawIssueDistribution(data) {
        const config = {
            type: 'doughnut',
            data: {
                labels: Object.keys(data.issues_by_type || {}),
                datasets: [{
                    data: Object.values(data.issues_by_type || {}),
                    backgroundColor: [
                        'var(--color-primary)',
                        'var(--color-success)',
                        'var(--color-danger)'
                    ]
                }]
            },
            options: {
                ...AgileUtils.getDefaultChartOptions(),
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        };
        
        this.charts.issueDistribution = AgileUtils.initChart('issue-distribution-chart', config);
    }
    
    createTeamMembers(data) {
        const card = AgileUtils.createElement('div', 'card');
        card.innerHTML = `<h3>👥 Team Members</h3>`;
        
        const content = AgileUtils.createElement('div');
        
        (data.team_members || []).forEach(member => {
            const memberEl = AgileUtils.createElement('div', 'team-member');
            memberEl.innerHTML = `
                <div class="avatar">${member.username.charAt(0).toUpperCase()}</div>
                <div class="member-info">
                    <div class="member-name">${member.username}</div>
                    <div class="member-stats">
                        ${member.active_issues} issues • ${member.completed_points} points
                    </div>
                </div>
                <span class="status status--${member.status}">${member.status}</span>
            `;
            content.appendChild(memberEl);
        });
        
        card.appendChild(content);
        return card;
    }
    
    createVelocityTrend(data) {
        const card = AgileUtils.createElement('div', 'card');
        card.innerHTML = `<h3>📊 Velocity Trend</h3>`;
        
        const chartContainer = AgileUtils.createElement('div', 'chart-container');
        chartContainer.style.height = '200px';
        const canvas = AgileUtils.createElement('canvas');
        canvas.id = 'velocity-trend-chart';
        chartContainer.appendChild(canvas);
        card.appendChild(chartContainer);
        
        setTimeout(() => this.drawVelocityTrend(data), 100);
        
        return card;
    }
    
    drawVelocityTrend(data) {
        if (!data.velocity_trend) return;
        
        const config = {
            type: 'bar',
            data: {
                labels: data.velocity_trend.map(v => v.week),
                datasets: [{
                    label: 'Velocity',
                    data: data.velocity_trend.map(v => v.velocity),
                    backgroundColor: 'var(--color-primary)',
                    borderRadius: 4
                }]
            },
            options: {
                ...AgileUtils.getDefaultChartOptions(),
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        };
        
        this.charts.velocityTrend = AgileUtils.initChart('velocity-trend-chart', config);
    }
    
    createQuickActions() {
        const card = AgileUtils.createElement('div', 'card');
        card.innerHTML = `
            <h3>⚡ Quick Actions</h3>
            <div class="quick-actions">
                <a href="https://github.com/${AgileUtils.REPO_OWNER}/${AgileUtils.REPO_NAME}/issues/new" class="btn btn--primary" target="_blank">New Issue</a>
                <a href="https://github.com/${AgileUtils.REPO_OWNER}/${AgileUtils.REPO_NAME}/issues" class="btn" target="_blank">View Issues</a>
                <a href="../burndown/" class="btn">Burndown Chart</a>
                <a href="https://github.com/${AgileUtils.REPO_OWNER}/${AgileUtils.REPO_NAME}/milestones" class="btn" target="_blank">Milestones</a>
                <a href="https://github.com/${AgileUtils.REPO_OWNER}/${AgileUtils.REPO_NAME}/projects" class="btn" target="_blank">Projects</a>
                <a href="https://github.com/${AgileUtils.REPO_OWNER}/${AgileUtils.REPO_NAME}/actions" class="btn" target="_blank">Actions</a>
            </div>
        `;
        
        const style = AgileUtils.createElement('style');
        style.textContent = `
            .quick-actions {
                display: flex;
                flex-direction: column;
                gap: 8px;
            }
            .quick-actions .btn {
                width: 100%;
                text-align: center;
            }
        `;
        card.appendChild(style);
        
        return card;
    }
    
    calculateRemainingDays(dueDate) {
        if (!dueDate) return '未設定';
        const today = new Date();
        const due = new Date(dueDate);
        const diff = Math.ceil((due - today) / (1000 * 60 * 60 * 24));
        if (diff < 0) return '期限切れ';
        if (diff === 0) return '今日';
        return `${diff}日`;
    }
    
    startAutoRefresh() {
        this.stopAutoRefresh();
        this.refreshTimer = setInterval(() => {
            this.loadDashboard();
        }, this.refreshInterval);
    }
    
    stopAutoRefresh() {
        if (this.refreshTimer) {
            clearInterval(this.refreshTimer);
            this.refreshTimer = null;
        }
    }
    
    destroy() {
        this.stopAutoRefresh();
        Object.values(this.charts).forEach(chart => {
            AgileUtils.destroyChart(chart);
        });
        this.charts = {};
    }
}

// Additional styles for team dashboard
const dashboardStyles = `
.team-member {
    display: flex;
    align-items: center;
    padding: 12px;
    background: var(--color-bg-secondary);
    border-radius: var(--radius-md);
    margin-bottom: 8px;
}

.avatar {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: var(--color-primary);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
    margin-right: 12px;
}

.member-info {
    flex: 1;
}

.member-name {
    font-weight: 500;
    color: var(--color-text-primary);
}

.member-stats {
    font-size: 0.875rem;
    color: var(--color-text-secondary);
}

.status {
    padding: 4px 8px;
    border-radius: var(--radius-sm);
    font-size: 0.75rem;
    text-transform: uppercase;
    font-weight: 500;
}

.status--active {
    background: var(--color-success);
    color: white;
}

.status--away {
    background: var(--color-warning);
    color: white;
}

.status--busy {
    background: var(--color-danger);
    color: white;
}

.metric {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 0;
    border-bottom: 1px solid rgba(0, 0, 0, 0.05);
}

.metric:last-child {
    border-bottom: none;
}

.metric-label {
    color: var(--color-text-secondary);
    font-size: 0.875rem;
}

.metric-value {
    font-weight: 600;
    color: var(--color-text-primary);
}
`;

// Inject styles
if (typeof document !== 'undefined') {
    const styleSheet = document.createElement('style');
    styleSheet.textContent = dashboardStyles;
    document.head.appendChild(styleSheet);
}