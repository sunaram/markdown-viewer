# Mathematics, beautifully typeset

Everything on this page is plain text in a `.md` file. Inline math like $e^{i\pi}+1=0$, $\sqrt{a^2+b^2}$ and $\Gamma(z)=\int_0^\infty t^{z-1}e^{-t}\,dt$ flows with the text, and display equations are centred. LaTeX is converted to **MathML**, which the system web view renders natively - no fonts or scripts are bundled.

## Analysis

$$\int_{-\infty}^{\infty} e^{-x^2}\,dx = \sqrt{\pi} \qquad\qquad \sum_{n=1}^{\infty}\frac{1}{n^2}=\frac{\pi^2}{6}$$

$$\hat{f}(\xi)=\int_{-\infty}^{\infty} f(x)\,e^{-2\pi i x\xi}\,dx \qquad\qquad \lim_{x\to 0}\frac{\sin x}{x}=1$$

$$\prod_{p\ \text{prime}}\frac{1}{1-p^{-s}}=\zeta(s) \qquad\qquad \binom{n}{k}=\frac{n!}{k!\,(n-k)!}$$

## Electromagnetism and quantum mechanics

$$\nabla\times\vec{B}=\mu_0\vec{J}+\mu_0\varepsilon_0\frac{\partial\vec{E}}{\partial t} \qquad\qquad \nabla\cdot\vec{E}=\frac{\rho}{\varepsilon_0}$$

$$i\hbar\frac{\partial}{\partial t}\Psi(\mathbf{r},t)=\left[-\frac{\hbar^2}{2m}\nabla^2+V(\mathbf{r},t)\right]\Psi(\mathbf{r},t)$$

$$\oint_C\vec{F}\cdot d\vec{r}=\iint_S(\nabla\times\vec{F})\cdot d\vec{S}$$

## Relativity and cosmology

$$G_{\mu\nu}+\Lambda g_{\mu\nu}=\frac{8\pi G}{c^4}\,T_{\mu\nu}$$

$$\mathrm{d}s^2=-c^2\mathrm{d}t^2+a(t)^2\left[\frac{\mathrm{d}r^2}{1-kr^2}+r^2\,\mathrm{d}\Omega^2\right] \qquad \left(\frac{\dot a}{a}\right)^2=\frac{8\pi G}{3}\rho-\frac{k}{a^2}$$

## Linear algebra

$$\begin{pmatrix}a&b\\c&d\end{pmatrix}\begin{pmatrix}x\\y\end{pmatrix}=\begin{pmatrix}ax+by\\cx+dy\end{pmatrix} \qquad R_x(\theta)=\begin{bmatrix}1&0&0\\0&\cos\theta&-\sin\theta\\0&\sin\theta&\cos\theta\end{bmatrix}$$

$$\det(A)=\begin{vmatrix}a&b\\c&d\end{vmatrix}=ad-bc \qquad \lVert x\rVert_2=\sqrt{\sum_i x_i^2}$$

## Probability, statistics and machine learning

$$P(A\mid B)=\frac{P(B\mid A)\,P(A)}{P(B)} \qquad \sigma^2=\frac{1}{N}\sum_{i=1}^{N}(x_i-\mu)^2 \qquad H(X)=-\sum_x p(x)\log_2 p(x)$$

$$\operatorname{softmax}(z)_i=\frac{e^{z_i}}{\sum_j e^{z_j}} \qquad \mathcal{L}(\theta)=-\sum_i y_i\log\hat{y}_i$$

| Quantity | Symbol | Formula |
|---|---|---|
| Quadratic roots | $x_{1,2}$ | $\dfrac{-b\pm\sqrt{b^2-4ac}}{2a}$ |
| Expectation | $\mathbb{E}[X]$ | $\sum_i x_i\,p_i$ |
| Euler product | $\zeta(s)$ | $\prod_p (1-p^{-s})^{-1}$ |
| Logic | $A\subseteq B$ | $\forall x\,(x\in A\to x\in B)$ |

## Raw MathML works too

Anything LaTeX can't express can be written as MathML directly. A piecewise function and a continued fraction:

<math display="block">
  <mrow><mi>f</mi><mo>(</mo><mi>x</mi><mo>)</mo></mrow><mo>=</mo>
  <mrow><mo>{</mo>
    <mtable columnalign="left left">
      <mtr><mtd><msup><mi>x</mi><mn>2</mn></msup></mtd><mtd><mtext>if&nbsp;</mtext><mi>x</mi><mo>&ge;</mo><mn>0</mn></mtd></mtr>
      <mtr><mtd><mo>&minus;</mo><mi>x</mi></mtd><mtd><mtext>otherwise</mtext></mtd></mtr>
    </mtable>
  </mrow>
  <mspace width="3em"/>
  <mi>&phi;</mi><mo>=</mo><mn>1</mn><mo>+</mo>
  <mfrac><mn>1</mn><mrow><mn>1</mn><mo>+</mo><mfrac><mn>1</mn><mrow><mn>1</mn><mo>+</mo><mfrac><mn>1</mn><mrow><mn>1</mn><mo>+</mo><mo>&hellip;</mo></mrow></mfrac></mrow></mfrac></mrow></mfrac>
</math>
