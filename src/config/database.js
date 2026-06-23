const mysql = require('mysql2/promise');

let pool;

module.exports = {
  connect: async () => {
    pool = mysql.createPool({
      host:     process.env.DB_HOST || 'localhost',
      port:     Number(process.env.DB_PORT || 3306),
      database: process.env.DB_NAME,
      user:     process.env.DB_USER,
      password: process.env.DB_PASSWORD,
    });
    try {
      await pool.query('SELECT 1');
      console.log('MySQL connected');
    } catch (err) {
      console.error('MySQL connection failed:', err.message);
    }
  },
  query: (sql, params) => pool.query(sql, params),
};
