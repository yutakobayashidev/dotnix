---
name: functional-cohesion-components
description: Guide frontend component design and code review using functional cohesion. Use when designing, reviewing, or refactoring React/TypeScript UI components with multiple roles, similar screens, conditional rendering, API-union-driven UI, notifications, directory/file rows, create/edit forms, or when deciding whether to split, merge, or commonize components.
---

# Functional Cohesion Components

## Purpose

Use functional cohesion to keep frontend components aligned with product responsibilities. Prefer components that represent one meaningful feature, role, or workflow over components that switch many responsibilities with flags.

Use this skill to answer: "Should this UI be one component with conditions, split into multiple components, or partially commonized?"

## Core Rule

Prefer functional cohesion:

- Split by responsibility when UI represents different roles, workflows, permissions, states, or user intentions.
- Commonize only a meaningful unit, not a visually similar fragment.
- Keep unavoidable branching near the boundary that decides what feature is being rendered.
- Avoid logical cohesion: one component that groups similar-looking behavior and switches responsibilities with `role`, `type`, or many boolean flags.

Do not apply this mechanically. If a split creates components with almost no responsibility, keep the component together and use a small feature-named extension point.

## Review Workflow

1. Identify the feature boundary.
   Ask what product responsibility the component represents: buyer view, seller view, admin operation, notification kind, file row, directory row, create page, edit page, etc.

2. List the differences.
   Check displayed data, actions, navigation target, permissions, validation, empty/error states, mobile behavior, and future variation risk.

3. Decide where branching belongs.
   Prefer route/page boundaries first. If data type decides the branch, put the branch in a parent, list mapper, or small dispatcher component. Keep child components focused.

4. Evaluate commonization.
   Commonize only when the unit is also meaningfully shared in requirements, Figma grouping/componentization, API schema shape, and local code conventions.

5. Check for over-splitting.
   If a split only wraps one extra line around a large shared component, use a small feature-named prop or slot instead.

6. State the tradeoff.
   In reviews, say which responsibility is being isolated, what future conditions are avoided, and what duplication is intentionally accepted.

## Patterns

### Route-Separable Screens

When routing already separates roles or page purposes, let the route call different page components.

Good examples:

- `BuyerProductPage` and `SellerProductPage` from role-specific routes.
- `CreateProductPage` and `EditProductPage` as separate pages.
- A shared `ProductForm` only when schema and field responsibility are truly the same.

For create/edit forms, keep title, default values, and submit handler in the page. Let the form render fields and invoke passed handlers.

Avoid hiding route-level responsibilities behind a role prop:

```tsx
export const ProductDetail = ({
	product,
	role,
}: {
	product: Product;
	role: 'buyer' | 'seller';
}) => (
	<div>
		<h2>{product.name}</h2>
		<p>{product.description}</p>
		{role === 'buyer' && <button>Add to cart</button>}
		{role === 'seller' && <button>Edit</button>}
	</div>
);
```

Prefer role-specific page or feature components when the role has its own responsibility:

```tsx
export const BuyerProductDetail = ({ product }: { product: Product }) => (
	<div>
		<ProductBasicInfo product={product} />
		<button>Add to cart</button>
	</div>
);

export const SellerProductDetail = ({ product }: { product: Product }) => (
	<div>
		<ProductBasicInfo product={product} />
		<button>Edit</button>
	</div>
);

const ProductBasicInfo = ({ product }: { product: Product }) => (
	<section>
		<h2>{product.name}</h2>
		<p>{product.description}</p>
	</section>
);
```

For create/edit, share the form only after moving page-specific responsibility upward:

```tsx
export const CreateProductPage = () => (
	<ProductForm
		title="Add New Product"
		defaultValues={{ name: '', price: '', description: '' }}
		submitLabel="Create"
		onSubmit={createProduct}
	/>
);

export const EditProductPage = ({ product }: { product: Product }) => (
	<ProductForm
		title="Edit Product"
		defaultValues={product}
		submitLabel="Edit"
		onSubmit={(values) => updateProduct(product.id, values)}
	/>
);
```

### Data-Type Branching

When API data determines the UI type, a branch is unavoidable. Do not scatter the same branch across icon, click handler, menu items, and layout.

Prefer:

- A parent dispatcher such as `FileSystemRow`.
- A `list.map()` branch that chooses `DirectoryRow` or `FileRow`.
- Exhaustive matching for discriminated unions.

Use TypeScript discriminated unions or `ts-pattern` with `.exhaustive()` when the API schema defines variants such as notification kinds. This makes new backend variants fail type-checking until the UI handles them.

Avoid repeating the same discriminator throughout one row:

```tsx
const StorageItemRow = ({ item }: { item: StorageItem }) => (
	<tr onClick={() => (item.type === 'folder' ? openFolder(item.id) : previewFile(item.id))}>
		<td>
			{item.type === 'folder' ? <FolderIcon /> : <FileIcon />} {item.name}
		</td>
		<td>
			{item.type === 'file' && <button onClick={() => downloadFile(item.id)}>Download</button>}
			{item.type === 'file' && <button onClick={() => deleteFile(item.id)}>Delete</button>}
		</td>
	</tr>
);
```

Prefer one branch at the boundary, then focused rows:

```tsx
const StorageItemRow = ({ item }: { item: StorageItem }) => {
	switch (item.type) {
		case 'folder':
			return <FolderRow folder={item} />;
		case 'file':
			return <FileRow file={item} />;
	}
};
```

For notifications, let exhaustive matching express that each notification kind is its own feature:

```tsx
const NotificationItem = ({ notification }: { notification: Notification }) =>
	match(notification)
		.with({ type: 'OrderCreated' }, ({ orderId, createdAt }) => (
			<OrderCreatedNotification orderId={orderId} createdAt={createdAt} />
		))
		.with({ type: 'ProductLiked' }, ({ productId, createdAt }) => (
			<ProductLikedNotification productId={productId} createdAt={createdAt} />
		))
		.with({ type: 'MessageReceived' }, ({ chatId, createdAt }) => (
			<MessageReceivedNotification chatId={chatId} createdAt={createdAt} />
		))
		.exhaustive();
```

### Commonization Pressure

When two areas look similar, verify they are functionally related before sharing code.

Use these signals:

- Requirements describe the same concept.
- Figma groups or components the same unit.
- API schema uses the same object shape for the same domain concept.
- Existing codebase convention splits at the same grain.

Be skeptical when a buyer-facing history screen resembles an admin order-management screen, or when `User` and `SellerUser` look similar but encode different concepts.

### Small Differences

When differences are tiny, splitting by role can create thin and unbalanced components.

Accept a small feature-named prop when it is local and limited:

```tsx
<ProductDetail product={product} showEditButton />
```

Prefer names like `showEditButton`, `showStockWarning`, or `extraProductInfo` over `role="seller"` or `type="admin"`. One or two such options can be reasonable; many options indicate the component wants to split.

Use `ReactNode` or `children` slots sparingly. Name the slot after the feature, not the layout position, because the child component cannot otherwise reveal what is injected.

Use a feature-named prop for a tiny local variation:

```tsx
export const ProductDetail = ({
	product,
	showEditButton = false,
}: {
	product: Product;
	showEditButton?: boolean;
}) => (
	<div>
		<h2>{product.name}</h2>
		<p>{product.description}</p>
		{showEditButton && <button>Edit</button>}
	</div>
);
```

Use a named slot only when the parent owns the extra feature and the base component still has a clear responsibility:

```tsx
export const ProductDetail = ({
	product,
	extraProductInfo,
}: {
	product: Product;
	extraProductInfo?: React.ReactNode;
}) => (
	<div>
		<h2>{product.name}</h2>
		<p>{product.description}</p>
		{extraProductInfo}
	</div>
);
```

## Warning Signs

Treat these as review findings:

- The same `role` or `type` check appears in several places inside one component.
- Boolean flags describe roles or modes instead of concrete features.
- A "shared" component needs comments explaining which role owns which lines.
- Adding a new role requires auditing unrelated branches.
- UI similarity is the only reason for commonization.
- A child component mixes navigation, permissions, and rendering for multiple domain concepts.
- Branching exists at both parent and child levels for the same discriminator.

## Review Output

When reviewing code, structure the answer as:

1. Current cohesion: functional, logical, or mixed.
2. Main risk: the concrete branch or shared unit likely to grow.
3. Recommended boundary: route/page, dispatcher, row/component, form, or feature prop.
4. Duplication decision: what to duplicate intentionally and what to share.
5. Verification: type exhaustiveness, affected role flows, and tests or story cases to cover.

Keep recommendations simple. Prefer the smallest change that moves responsibility boundaries closer to product meaning.
