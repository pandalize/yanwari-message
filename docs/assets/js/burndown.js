class BurndownChart {
    constructor(options = {}) {
        this.containerId = options.containerId || 'burndown-container';
        this.chartCanvasId = options.chartCanvasId || 'burndownChart';
        this.selectorId = options.selectorId || 'milestone-select';
        this.chart = null;
        this.currentData = null;
        
        this.init();
    }
    
    async init() {
        await this.loadAvailableSprints();
        this.attachEventListeners();
    }
    
    async loadAvailableSprints() {
        const container = document.getElementById(this.containerId);
        if (!container) return;
        
        AgileUtils.showLoading(container);
        
        try {
            const sprints = await AgileUtils.getAvailableSprints();
            
            if (sprints.length === 0) {
                this.showNoDataMessage();
                return;
            }
            
            this.populateSprintSelector(sprints);
            await this.loadSprint(sprints[0]);
            
        } catch (error) {
            console.error('Failed to load sprints:', error);
            AgileUtils.showError(container, 'スプリントデータの読み込みに失敗しました');
        }
    }
    
    populateSprintSelector(sprints) {
        const selector = document.getElementById(this.selectorId);
        if (!selector) return;
        
        selector.innerHTML = '<option value="">選択してください</option>';
        
        sprints.forEach(sprintNumber => {
            const option = AgileUtils.createElement('option', '', `Sprint ${sprintNumber}`);
            option.value = sprintNumber;
            selector.appendChild(option);
        });
        
        if (sprints.length > 0) {
            selector.value = sprints[0];
        }
    }
    
    async loadSprint(sprintNumber) {
        if (!sprintNumber) {
            this.showNoDataMessage();
            return;
        }
        
        const container = document.getElementById(this.containerId);
        AgileUtils.showLoading(container);
        
        try {
            const data = await AgileUtils.fetchSprintData(sprintNumber);
            this.currentData = data;
            this.render(data);
        } catch (error) {
            console.error(`Failed to load sprint ${sprintNumber}:`, error);
            this.showNoDataMessage();
        }
    }
    
    render(data) {
        const container = document.getElementById(this.containerId);
        container.innerHTML = '';
        
        const header = this.createHeader(data);
        const stats = this.createStats(data);
        const chartContainer = this.createChartContainer();
        const footer = this.createFooter(data);
        
        container.appendChild(header);
        container.appendChild(stats);
        container.appendChild(chartContainer);
        container.appendChild(footer);
        
        this.drawChart(data);
    }
    
    createHeader(data) {
        const header = AgileUtils.createElement('div', 'card mb-3');
        header.innerHTML = `
            <h2>${data.milestone.title}</h2>
            <p class="text-muted">${data.milestone.description || 'Sprint in progress'}</p>
        `;
        return header;
    }
    
    createStats(data) {
        const statsContainer = AgileUtils.createElement('div', 'grid grid--stats mb-3');
        
        const latestData = data.daily_data[data.daily_data.length - 1];
        if (!latestData) return statsContainer;
        
        const completionRate = AgileUtils.calculatePercentage(
            latestData.completed_points,
            latestData.total_points
        );
        
        const velocity = AgileUtils.calculateVelocity(data.daily_data);
        const prediction = AgileUtils.predictCompletion(latestData.remaining_points, velocity);
        
        const stats = [
            { label: '総ポイント', value: latestData.total_points, class: '' },
            { label: '残りポイント', value: latestData.remaining_points, class: 'stat-card--warning' },
            { label: '完了率', value: `${completionRate}%`, class: 'stat-card--success' },
            { label: '期限', value: AgileUtils.formatDate(data.milestone.due_on), class: '' },
            { label: '平均ベロシティ', value: `${velocity.toFixed(1)} pts/日`, class: '' },
            { label: '完了予測日', value: prediction, class: completionRate >= 80 ? 'stat-card--success' : '' }
        ];
        
        stats.forEach(stat => {
            const card = AgileUtils.createStatCard(stat.label, stat.value, stat.class);
            statsContainer.appendChild(card);
        });
        
        return statsContainer;
    }
    
    createChartContainer() {
        const container = AgileUtils.createElement('div', 'card');
        const chartDiv = AgileUtils.createElement('div', 'chart-container');
        const canvas = AgileUtils.createElement('canvas');
        canvas.id = this.chartCanvasId;
        
        chartDiv.appendChild(canvas);
        container.appendChild(chartDiv);
        
        return container;
    }
    
    createFooter(data) {
        const footer = AgileUtils.createElement('div', 'text-center text-muted mt-3');
        const latestData = data.daily_data[data.daily_data.length - 1];
        if (latestData) {
            footer.textContent = `最終更新: ${AgileUtils.formatDate(latestData.date)}`;
        }
        return footer;
    }
    
    drawChart(data) {
        AgileUtils.destroyChart(this.chart);
        
        const labels = data.daily_data.map(d => {
            const date = new Date(d.date);
            return `${date.getMonth() + 1}/${date.getDate()}`;
        });
        
        const remainingPoints = data.daily_data.map(d => d.remaining_points);
        const completedPoints = data.daily_data.map(d => d.completed_points);
        
        const totalPoints = data.daily_data[0]?.total_points || 0;
        const idealLine = data.daily_data.map((_, index) => {
            const progress = index / Math.max(data.daily_data.length - 1, 1);
            return Math.max(0, totalPoints * (1 - progress));
        });
        
        const config = {
            type: 'line',
            data: {
                labels: labels,
                datasets: [
                    {
                        label: '残りポイント',
                        data: remainingPoints,
                        borderColor: 'var(--color-danger)',
                        backgroundColor: 'rgba(215, 58, 74, 0.1)',
                        tension: 0.2,
                        pointBackgroundColor: 'var(--color-danger)',
                        pointBorderColor: '#ffffff',
                        pointBorderWidth: 2,
                        pointRadius: 5,
                        fill: true
                    },
                    {
                        label: '完了ポイント',
                        data: completedPoints,
                        borderColor: 'var(--color-success)',
                        backgroundColor: 'rgba(46, 160, 67, 0.1)',
                        tension: 0.2,
                        pointBackgroundColor: 'var(--color-success)',
                        pointBorderColor: '#ffffff',
                        pointBorderWidth: 2,
                        pointRadius: 4,
                        fill: false
                    },
                    {
                        label: '理想線',
                        data: idealLine,
                        borderColor: 'var(--color-primary)',
                        backgroundColor: 'transparent',
                        borderDash: [5, 5],
                        tension: 0.1,
                        pointRadius: 0,
                        fill: false
                    }
                ]
            },
            options: {
                ...AgileUtils.getDefaultChartOptions(),
                plugins: {
                    ...AgileUtils.getDefaultChartOptions().plugins,
                    title: {
                        display: true,
                        text: 'Sprint Burndown Chart',
                        font: {
                            size: 16,
                            weight: '500'
                        }
                    }
                },
                scales: {
                    y: {
                        ...AgileUtils.getDefaultChartOptions().scales.y,
                        title: {
                            display: true,
                            text: 'Story Points',
                            font: {
                                size: 14
                            }
                        }
                    },
                    x: {
                        ...AgileUtils.getDefaultChartOptions().scales.x,
                        title: {
                            display: true,
                            text: 'Date',
                            font: {
                                size: 14
                            }
                        }
                    }
                },
                interaction: {
                    intersect: false,
                    mode: 'index'
                }
            }
        };
        
        this.chart = AgileUtils.initChart(this.chartCanvasId, config);
    }
    
    showNoDataMessage() {
        const container = document.getElementById(this.containerId);
        container.innerHTML = '';
        
        const alert = AgileUtils.createElement('div', 'alert alert--warning');
        alert.innerHTML = `
            <h3>📊 データがありません</h3>
            <p>まだスプリントデータが生成されていません。</p>
            <div class="mt-3">
                <h4>セットアップ手順:</h4>
                <ol>
                    <li>GitHubリポジトリでIssueを作成し、<code>estimate/X</code>ラベルを設定</li>
                    <li>Milestoneを作成してIssueを割り当て</li>
                    <li>GitHub ActionsのBurndown workflowを手動実行</li>
                    <li>または平日朝9時の自動実行を待つ</li>
                </ol>
            </div>
        `;
        container.appendChild(alert);
    }
    
    attachEventListeners() {
        const selector = document.getElementById(this.selectorId);
        if (selector) {
            selector.addEventListener('change', (e) => {
                this.loadSprint(e.target.value);
            });
        }
    }
    
    refresh() {
        if (this.currentData) {
            this.render(this.currentData);
        } else {
            this.loadAvailableSprints();
        }
    }
    
    destroy() {
        AgileUtils.destroyChart(this.chart);
        this.chart = null;
        this.currentData = null;
    }
}