const AgileUtils = (() => {
    
    const API_BASE = 'https://api.github.com';
    const REPO_OWNER = 'pandalize';
    const REPO_NAME = 'agile';
    
    const formatDate = (dateString, locale = 'ja-JP') => {
        if (!dateString) return '未設定';
        return new Date(dateString).toLocaleDateString(locale);
    };
    
    const formatDateTime = (dateString, locale = 'ja-JP') => {
        if (!dateString) return '未設定';
        return new Date(dateString).toLocaleString(locale);
    };
    
    const calculatePercentage = (completed, total) => {
        if (total === 0) return 0;
        return Math.round((completed / total) * 100);
    };
    
    const calculateVelocity = (dailyData) => {
        if (!dailyData || dailyData.length < 2) return 0;
        
        let totalBurned = 0;
        for (let i = 1; i < dailyData.length; i++) {
            const burned = dailyData[i-1].remaining_points - dailyData[i].remaining_points;
            if (burned > 0) totalBurned += burned;
        }
        return totalBurned / (dailyData.length - 1);
    };
    
    const predictCompletion = (remainingPoints, velocity, locale = 'ja-JP') => {
        if (velocity <= 0 || !remainingPoints) return '予測不可';
        
        const daysToComplete = Math.ceil(remainingPoints / velocity);
        const today = new Date();
        const completionDate = new Date(today);
        completionDate.setDate(today.getDate() + daysToComplete);
        
        return completionDate.toLocaleDateString(locale);
    };
    
    const fetchJSON = async (url) => {
        try {
            const response = await fetch(url);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return await response.json();
        } catch (error) {
            console.error('Fetch error:', error);
            throw error;
        }
    };
    
    const fetchGitHubData = async (endpoint) => {
        const url = `${API_BASE}/repos/${REPO_OWNER}/${REPO_NAME}/${endpoint}`;
        return fetchJSON(url);
    };
    
    const fetchSprintData = async (sprintNumber) => {
        const url = `https://${REPO_OWNER}.github.io/${REPO_NAME}/burndown/sprint-${sprintNumber}.json`;
        return fetchJSON(url);
    };
    
    const getAvailableSprints = async () => {
        try {
            const files = await fetchGitHubData('contents/docs/burndown');
            return files
                .filter(file => file.name.startsWith('sprint-') && file.name.endsWith('.json'))
                .map(file => {
                    const match = file.name.match(/sprint-(\d+)\.json/);
                    return match ? parseInt(match[1]) : null;
                })
                .filter(num => num !== null)
                .sort((a, b) => b - a);
        } catch (error) {
            console.error('Failed to get available sprints:', error);
            return [];
        }
    };
    
    const createElement = (tag, className = '', content = '') => {
        const element = document.createElement(tag);
        if (className) element.className = className;
        if (content) element.textContent = content;
        return element;
    };
    
    const createStatCard = (label, value, className = '') => {
        const card = createElement('div', `stat-card ${className}`);
        const labelEl = createElement('div', 'stat-label', label);
        const valueEl = createElement('div', 'stat-value', value);
        card.appendChild(labelEl);
        card.appendChild(valueEl);
        return card;
    };
    
    const showLoading = (container) => {
        const loading = createElement('div', 'loading');
        loading.textContent = 'データを読み込み中';
        container.innerHTML = '';
        container.appendChild(loading);
    };
    
    const showError = (container, message = 'エラーが発生しました') => {
        const alert = createElement('div', 'alert alert--error');
        alert.textContent = message;
        container.innerHTML = '';
        container.appendChild(alert);
    };
    
    const showNoData = (container, message = 'データがありません') => {
        const alert = createElement('div', 'alert alert--info');
        alert.textContent = message;
        container.innerHTML = '';
        container.appendChild(alert);
    };
    
    const debounce = (func, wait) => {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    };
    
    const throttle = (func, limit) => {
        let inThrottle;
        return function(...args) {
            if (!inThrottle) {
                func.apply(this, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    };
    
    const groupBy = (array, key) => {
        return array.reduce((result, item) => {
            const group = item[key];
            if (!result[group]) result[group] = [];
            result[group].push(item);
            return result;
        }, {});
    };
    
    const sortBy = (array, key, ascending = true) => {
        return [...array].sort((a, b) => {
            const aVal = a[key];
            const bVal = b[key];
            if (aVal < bVal) return ascending ? -1 : 1;
            if (aVal > bVal) return ascending ? 1 : -1;
            return 0;
        });
    };
    
    const getColorForStatus = (status) => {
        const statusColors = {
            'open': 'var(--color-primary)',
            'closed': 'var(--color-success)',
            'in_progress': 'var(--color-warning)',
            'blocked': 'var(--color-danger)',
            'todo': 'var(--color-text-secondary)'
        };
        return statusColors[status] || 'var(--color-text-primary)';
    };
    
    const getColorForPriority = (priority) => {
        const priorityColors = {
            'high': 'var(--color-danger)',
            'medium': 'var(--color-warning)',
            'low': 'var(--color-success)'
        };
        return priorityColors[priority] || 'var(--color-text-secondary)';
    };
    
    const parseLabels = (labels) => {
        const result = {
            priority: null,
            type: null,
            estimate: null,
            status: null,
            others: []
        };
        
        labels.forEach(label => {
            const name = label.name.toLowerCase();
            if (name.startsWith('priority:')) {
                result.priority = name.replace('priority:', '').trim();
            } else if (name.startsWith('type:')) {
                result.type = name.replace('type:', '').trim();
            } else if (name.startsWith('estimate:')) {
                result.estimate = parseInt(name.replace('estimate:', '').trim()) || 0;
            } else if (name.startsWith('status:')) {
                result.status = name.replace('status:', '').trim();
            } else {
                result.others.push(label);
            }
        });
        
        return result;
    };
    
    const initChart = (canvasId, config) => {
        const canvas = document.getElementById(canvasId);
        if (!canvas) {
            console.error(`Canvas element with id '${canvasId}' not found`);
            return null;
        }
        
        const ctx = canvas.getContext('2d');
        return new Chart(ctx, config);
    };
    
    const destroyChart = (chart) => {
        if (chart) {
            chart.destroy();
        }
    };
    
    const getDefaultChartOptions = () => ({
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: true,
                position: 'top',
                labels: {
                    usePointStyle: true,
                    padding: 15
                }
            },
            tooltip: {
                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                padding: 12,
                cornerRadius: 4,
                titleFont: {
                    size: 14
                },
                bodyFont: {
                    size: 13
                }
            }
        },
        scales: {
            y: {
                beginAtZero: true,
                grid: {
                    color: 'rgba(0, 0, 0, 0.05)'
                }
            },
            x: {
                grid: {
                    color: 'rgba(0, 0, 0, 0.05)'
                }
            }
        }
    });
    
    return {
        formatDate,
        formatDateTime,
        calculatePercentage,
        calculateVelocity,
        predictCompletion,
        fetchJSON,
        fetchGitHubData,
        fetchSprintData,
        getAvailableSprints,
        createElement,
        createStatCard,
        showLoading,
        showError,
        showNoData,
        debounce,
        throttle,
        groupBy,
        sortBy,
        getColorForStatus,
        getColorForPriority,
        parseLabels,
        initChart,
        destroyChart,
        getDefaultChartOptions,
        API_BASE,
        REPO_OWNER,
        REPO_NAME
    };
})();