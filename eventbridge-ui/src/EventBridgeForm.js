import { useState, useEffect } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { sendEvent } from './EventBridgeClient';

function getFormattedDate() {
  const now = new Date();
  const yyyy = now.getFullYear();
  const MM = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const hh = String(now.getHours()).padStart(2, '0');
  const mm = String(now.getMinutes()).padStart(2, '0');
  const ss = String(now.getSeconds()).padStart(2, '0');
  return `${yyyy}-${MM}-${dd} ${hh}:${mm}:${ss}`;
}

function getRandomPrice() {
  const price = (Math.random() * (1000 - 1) + 1).toFixed(2);
  return price;
}

function getRandomProductId() {
  const randomNumber = Math.floor(1000 + Math.random() * 9000); // 1000〜9999 のランダムな4桁
  return `PROD-${randomNumber}`;
}

function getRandomQuantity() {
  return Math.floor(Math.random() * 100) + 1; // 1〜100
}

export default function EventBridgeForm() {
  const [formData, setFormData] = useState({
    contractId: uuidv4(),
    customerId: uuidv4(),
    productId: getRandomProductId(),
    price: getRandomPrice(),
    quantity: getRandomQuantity().toString(), 
    create_date: getFormattedDate(),
    update_date: getFormattedDate(),
  });

  const [message, setMessage] = useState('');
  const [isError, setIsError] = useState(false);

  // デバッグ：formData の更新ログ
  useEffect(() => {
    console.log('[DEBUG] formData updated:', formData);
  }, [formData]);

  const handleChange = (e) => {
    console.log('[DEBUG] input changed:', e.target.name, e.target.value);
    setFormData((prev) => ({
      ...prev,
      [e.target.name]: e.target.value,
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    try {
      const result = await sendEvent('MyDetailType', formData);
      setMessage('Event sent successfully!');
      setIsError(false);

      setTimeout(() => {
        window.location.reload();
      }, 3000); // 3秒後にリロード

    } catch (err) {
      console.error('[DEBUG] Failed to send event:', err);
      setMessage('Failed to send event.');
      setIsError(true);
    }
  };

  return (
    <div className="flex justify-end mt-10">
      <div className="p-6 bg-white shadow-md rounded-md w-full">
        <form onSubmit={handleSubmit}>
          <table className="w-full text-left border-collapse">
            <tbody>
              {Object.entries(formData).map(([key, value]) => (
                <tr key={key} className="border-b hover:bg-gray-50">
                  <td className="py-3 pr-4 font-medium text-gray-600 w-1/4">{key}</td>
                  <td className="py-3">
                    <input
                      type="text"
                      name={key}
                      value={value}
                      onChange={handleChange}
                      className="w-full border border-gray-300 px-4 py-2 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-600"
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="flex justify-end mt-6 pr-4">
            <button
              type="submit"
              className="bg-yellow-400 hover:bg-yellow-500 text-black font-bold py-2 px-4 rounded shadow"
            >
              送信
            </button>
          </div>

          {message && (
            <div className={`mt-4 text-sm font-semibold ${isError ? 'text-red-600' : 'text-green-600'}`}>
              {message}
            </div>
          )}
        </form>
      </div>
    </div>
  );
}