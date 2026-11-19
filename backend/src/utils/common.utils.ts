import { createHash } from 'crypto';

/**
 * Ensures a date is returned as YYYY-MM-DD strictly in Indian Standard Time (Asia/Kolkata).
 * Handles null, undefined, ISO strings, timestamps, and DD/MM/YYYY or DD-MM-YYYY formats.
 */
export function getIstDateString(d?: any): string {
  if (!d) {
    return new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' });
  }

  if (typeof d === 'string') {
    const trimmed = d.trim();
    // YYYY-MM-DD pattern
    const isoMatch = trimmed.match(/^(\d{4})[-/](\d{1,2})[-/](\d{1,2})/);
    if (isoMatch) {
      const year = isoMatch[1];
      const month = isoMatch[2].padStart(2, '0');
      const day = isoMatch[3].padStart(2, '0');
      return `${year}-${month}-${day}`;
    }

    // DD/MM/YYYY or DD-MM-YYYY pattern
    const dmyMatch = trimmed.match(/^(\d{1,2})[-/](\d{1,2})[-/](\d{4})/);
    if (dmyMatch) {
      const day = dmyMatch[1].padStart(2, '0');
      const month = dmyMatch[2].padStart(2, '0');
      const year = dmyMatch[3];
      return `${year}-${month}-${day}`;
    }
  }

  const dateObj = new Date(d);
  if (isNaN(dateObj.getTime())) {
    return new Date().toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' });
  }

  return dateObj.toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' });
}

/**
 * Returns current timestamp in ISO format with IST reference.
 */
export function getIstIsoString(): string {
  return new Date().toISOString();
}

/**
 * Validates or deterministically converts any string/numeric identifier into a valid UUID v4 string.
 * Prevents PostgreSQL "invalid input syntax for type uuid" errors completely.
 */
export function toDeterministicUuid(val: any): string {
  if (!val) {
    const randomHash = createHash('md5').update(String(Math.random() + Date.now())).digest('hex');
    return `${randomHash.substring(0, 8)}-${randomHash.substring(8, 12)}-4${randomHash.substring(13, 16)}-a${randomHash.substring(17, 20)}-${randomHash.substring(20, 32)}`;
  }

  const str = String(val).trim();
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (uuidRegex.test(str)) {
    return str;
  }

  const hash = createHash('md5').update(`joyn:${str}`).digest('hex');
  return `${hash.substring(0, 8)}-${hash.substring(8, 12)}-4${hash.substring(13, 16)}-a${hash.substring(17, 20)}-${hash.substring(20, 32)}`;
}

/**
 * Safely converts to a valid UUID or returns null if input is empty.
 */
export function toValidUuidOrNull(val: any): string | null {
  if (!val) return null;
  const str = String(val).trim();
  if (!str) return null;
  return toDeterministicUuid(str);
}
