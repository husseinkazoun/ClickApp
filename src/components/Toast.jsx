// src/components/Toast.jsx
import { useEffect } from "react";

export default function Toast({ open, type="info", message, onClose, timeout=3000 }) {
  useEffect(() => {
    if (!open) return;
    const id = setTimeout(() => onClose?.(), timeout);
    return () => clearTimeout(id);
  }, [open, timeout, onClose]);

  if (!open) return null;

  const bg =
    type === "error"   ? "bg-red-600"   :
    type === "success" ? "bg-teal-600"  : "bg-slate-700";

  return (
    <div
      className={`fixed bottom-6 left-1/2 -translate-x-1/2 text-white ${bg} px-4 py-2 rounded-lg shadow-lg`}
      role="status"
      aria-live="polite"
    >
      {message}
    </div>
  );
}
