// stripe-config.js - Configuração real do Stripe Checkout
const STRIPE_PUBLISHABLE_KEY = 'pk_test_placeholder'; // Será substituído automaticamente
const PRODUCTS = {
    47: { name: 'Ω-Conditions AI License', price: 4700, description: 'Licença anual do sistema autônomo' },
    97: { name: 'Autonomous Scale Package', price: 9700, description: 'Pacote de escalabilidade + suporte prioritário' },
    29: { name: 'Daily Revenue Report', price: 2900, description: 'Relatório diário de receita e insights' },
    199: { name: 'Full V3 System (Monthly)', price: 19900, description: 'Acesso completo ao sistema V3 por 30 dias' }
};

async function createCheckout(amount) {
    const product = PRODUCTS[amount];
    if (!product) return;
    
    try {
        const response = await fetch('/api/create-checkout', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ amount: amount, product: product })
        });
        const data = await response.json();
        if (data.url) {
            window.location.href = data.url;
        } else {
            alert('Erro ao criar checkout. Tente novamente.');
        }
    } catch (error) {
        console.error('Checkout error:', error);
        alert('Erro de conexão. Tente novamente.');
    }
}
